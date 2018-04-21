global with sharing class TransferController {
  global TransferController() {

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
      InventoryMoveWrapper imw = InventoryManager.createInventoryMoveWrapper( InventoryMoveWrapper.TRANSFER );
      imw.getRecord().transfer_from_warehouse__c = (Id)record.get('warehouseId');
      InventoryMoveLineOutboundWrapper transferLine = new InventoryMoveLineOutboundWrapper( new InventoryMoveLineOutbound__c() );
      transferLine.getRecord().barcode__c = (Id)record.get('Id');
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
