global with sharing class DisposeController {

    public List<Warehouse__c> warehouses1 {get;set;}
    public String warehouses_s {get;set;}
    public String selectedWarehouseId {get;set;}

  global DisposeController() {

    selectedWarehouseId = null;
    // try to figure out the last warehouse he made deposit to
    List<InventoryMove__c> disposes = [
        SELECT transfer_to_warehouse__c
        FROM InventoryMove__c
        WHERE
            CreatedById =:UserInfo.getUserId() AND
            recordTypeId =: InventoryMoveWrapper.getRecordTypeId(InventoryMoveWrapper.DISPOSE) AND
            transfer_to_warehouse__c != NULL
        ORDER BY CreatedDate DESC
        LIMIT 1
    ];

    if ( disposes.size() > 0 ) {
        selectedWarehouseId = String.valueOf( disposes[0].transfer_to_warehouse__c );
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
  global static Object saveDisposeBarcodeMove( String jsonStr ){
    // 倉庫 Id、商品 ID の確認
    // TODO fix this to be dynamic
    //Map<String, Object> jsonObj = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
    List<Object> barcodeList = (List<Object>) JSON.deserializeUntyped(jsonStr);
    for(Object recordObj : barcodeList){
      Map<String, Object> record = (Map<String, Object>) recordObj;
      InventoryMoveWrapper imw = InventoryManager.createInventoryMoveWrapper( InventoryMoveWrapper.DISPOSE );
      imw.getRecord().transfer_from_warehouse__c = (Id)record.get('warehouseId');
      InventoryMoveLineOutboundWrapper disposeLine = new InventoryMoveLineOutboundWrapper( new InventoryMoveLineOutbound__c() );
      disposeLine.getRecord().barcode__c = (Id)record.get('Id');
      disposeLine.getRecord().outbound_quantity__c = (decimal)record.get('shipped_quantity__c');
      imw.addInventoryMoveLineOutboundWrapper( disposeLine );
      imw.confirmInventoryMove();
    }

    return true;
  }

  @RemoteAction
  global static List<FoodTypeLOne__c> getFoodTypeLOne(){
    return [SELECT Id, Name FROM FoodTypeLOne__c];
  }

  @RemoteAction
  global static List<FoodTypeLTwo__c> getFoodTypeLTwo( String foodTypeLOneId ){
    return [SELECT Id, Name FROM FoodTypeLTwo__c WHERE food_type_lOne__c = :foodTypeLOneId];
  }

}
