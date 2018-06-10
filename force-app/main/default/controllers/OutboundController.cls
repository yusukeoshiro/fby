global with sharing class OutboundController {

  public Account toAccount {get;set;}
  public Contact toContact {get;set;}
  public String toObject {get;set;}
  public String toRecordId {get;set;}
  public List<Warehouse__c> warehouses1 {get;set;}
  public String warehouses_s {get;set;}
  public String selectedWarehouseId {get;set;}

  global OutboundController() {

          selectedWarehouseId = null;
          // try to figure out the last warehouse he made deposit to
          List<InventoryMove__c> outbounds = [
              SELECT transfer_to_warehouse__c
              FROM InventoryMove__c
              WHERE
                  CreatedById =:UserInfo.getUserId() AND
                  recordTypeId =: InventoryMoveWrapper.getRecordTypeId(InventoryMoveWrapper.OUTBOUND) AND
                  transfer_to_warehouse__c != NULL
              ORDER BY CreatedDate DESC
              LIMIT 1
          ];

          if ( outbounds.size() > 0 ) {
              selectedWarehouseId = String.valueOf( outbounds[0].transfer_to_warehouse__c );
          }

          warehouses1 = [SELECT Id, Name FROM Warehouse__c];
          warehouses_s = JSON.serialize( warehouses1 );

          if ( ApexPages.currentPage().getParameters().get('id') != null ) {
              String myId = ApexPages.currentPage().getParameters().get('id');

              List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id=: myId];
              if ( accounts.size() > 0 ) {
                  toAccount = accounts[0];
                  toObject = 'Account';
                  toRecordId = toAccount.Id;
              } else {
                  List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Id=:myId];
                  if ( contacts.size() > 0 ) {
                      toContact = contacts[0];
                      toObject = 'Contact';
                      toRecordId = toContact.Id;
                  }
              }

          }

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
  global static Object saveOutboundBarcodeMove( String objectName, String recordId, String warehouseId,  String jsonStr ){

    System.debug( objectName );
    System.debug( recordId );
    System.debug( warehouseId );

    // 倉庫 Id、商品 ID の確認
    // TODO fix this to be dynamic
    //Map<String, Object> jsonObj = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);
    List<Object> barcodeList = (List<Object>) JSON.deserializeUntyped(jsonStr);
    for(Object recordObj : barcodeList){
      Map<String, Object> record = (Map<String, Object>) recordObj;
      InventoryMoveWrapper imw = InventoryManager.createInventoryMoveWrapper( InventoryMoveWrapper.OUTBOUND );
      imw.getRecord().transfer_from_warehouse__c = (Id)record.get('warehouseId');
      InventoryMoveLineOutboundWrapper outboundLine = new InventoryMoveLineOutboundWrapper( new InventoryMoveLineOutbound__c() );
      outboundLine.getRecord().barcode__c = (Id)record.get('Id');
      outboundLine.getRecord().outbound_quantity__c = (decimal)record.get('shipped_quantity__c');

      if ( objectName == 'Contact' ) {
          imw.getRecord().donated_to_person__c = recordId;
      }
      if ( objectName == 'Account' ) {
          imw.getRecord().donated_to_company__c = recordId;
      }

      imw.addInventoryMoveLineOutboundWrapper( outboundLine );
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
