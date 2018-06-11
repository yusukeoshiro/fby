global with sharing class TransferController {

  public List<Warehouse__c> warehouses1 {get;set;}
  public String warehouses_s {get;set;}
  public String selectedWarehouseId {get;set;}

  global TransferController() {

      selectedWarehouseId = null;
      // try to figure out the last warehouse he made deposit to
      List<InventoryMove__c> transfers = [
          SELECT transfer_to_warehouse__c
          FROM InventoryMove__c
          WHERE
              CreatedById =:UserInfo.getUserId() AND
              recordTypeId =: InventoryMoveWrapper.getRecordTypeId(InventoryMoveWrapper.TRANSFER) AND
              transfer_to_warehouse__c != NULL
          ORDER BY CreatedDate DESC
          LIMIT 1
      ];

      if ( transfers.size() > 0 ) {
          selectedWarehouseId = String.valueOf( transfers[0].transfer_to_warehouse__c );
      }

      warehouses1 = [SELECT Id, Name FROM Warehouse__c];
      warehouses_s = JSON.serialize( warehouses1 );

  }

  @RemoteAction
  global static Object findBarcode( String barcode ){
    List<Barcode__c> barcodes = [SELECT Id, Name, current_inventory__r.warehouse__r.Name, current_inventory__r.product_name__c, remaining_quantity__c, expiration_date__c FROM Barcode__c WHERE Name =: barcode LIMIT 1];
    if( barcodes.size() > 0 ){
      return barcodes[0];
    }
    else{
      return null;
    }

  }

  @RemoteAction
  global static Object saveTransferBarcodeMove( String jsonStr ){
    // 倉庫 Idの確認
    //Map<String, Object> jsonObj = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
    List<Object> barcodeList = (List<Object>) JSON.deserializeUntyped(jsonStr);
    for(Object recordObj : barcodeList){
      Map<String, Object> record = (Map<String, Object>) recordObj;
      InventoryMoveWrapper imw = InventoryManager.createInventoryMoveWrapper(InventoryMoveWrapper.TRANSFER);
      imw.getRecord().transfer_from_warehouse__c  = (Id)record.get('fromWarehouseId'); // 移動元の倉庫のID
      imw.getRecord().transfer_to_warehouse__c    = (Id)record.get('toWarehouseId'); // 移動先の倉庫のID
      InventoryMoveLineOutboundWrapper transferLine = new InventoryMoveLineOutboundWrapper( new InventoryMoveLineOutbound__c() );
      transferLine.getRecord().barcode__c = (Id)record.get('Id'); // 移動させるバーコードのID
      imw.addInventoryMoveLineOutboundWrapper( transferLine );
      imw.confirmInventoryMove();
    }
    return true;
  }

  @RemoteAction
  global static List<Warehouse__c> getWarehouse(){
    return [SELECT Id, Name FROM Warehouse__c];
  }

}
