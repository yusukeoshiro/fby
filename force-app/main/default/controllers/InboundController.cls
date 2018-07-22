global with sharing class InboundController {

    public Account fromAccount {get;set;}
    public Contact fromContact {get;set;}
    public String fromObject {get;set;}
    public String fromRecordId {get;set;}
    public List<Warehouse__c> warehouses {get;set;}
    public String warehouses_s {get;set;}
    public String selectedWarehouseId {get;set;}
    public Map<String,String> productConditionPickList {get;set;}
    public Set<String> productionConditionKey {get;set;}

    global InboundController() {


        productConditionPickList = new Map<String,String>();
        productionConditionKey = new Set<String>();
        Schema.DescribeFieldResult fieldResult = InventoryMoveLine__c.product_condition__c.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry v : values) {
            productConditionPickList.put(v.getValue(),v.getLabel());
            productionConditionKey.add( v.getValue() );
        }

        selectedWarehouseId = null;
        // try to figure out the last warehouse he made deposit to
        List<InventoryMove__c> inbounds = [
            SELECT transfer_to_warehouse__c
            FROM InventoryMove__c
            WHERE
                CreatedById =:UserInfo.getUserId() AND
                recordTypeId =: InventoryMoveWrapper.getRecordTypeId(InventoryMoveWrapper.INBOUND) AND
                transfer_to_warehouse__c != NULL
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if ( inbounds.size() > 0 ) {
            selectedWarehouseId = String.valueOf( inbounds[0].transfer_to_warehouse__c );
        }

        warehouses = [SELECT Id, Name FROM Warehouse__c];
        warehouses_s = JSON.serialize( warehouses );

        if ( ApexPages.currentPage().getParameters().get('id') != null ) {
            String myId = ApexPages.currentPage().getParameters().get('id');

            List<Account> accounts = [SELECT Id, Name FROM Account WHERE Id=: myId];
            if ( accounts.size() > 0 ) {
                fromAccount = accounts[0];
                fromObject = 'Account';
                fromRecordId = fromAccount.Id;
            } else {
                List<Contact> contacts = [SELECT Id, Name FROM Contact WHERE Id=:myId];
                if ( contacts.size() > 0 ) {
                    fromContact = contacts[0];
                    fromObject = 'Contact';
                    fromRecordId = fromContact.Id;
                }
            }

        }
    }

    @RemoteAction
    global static Object getJanCode( String janCode ){
        JanProduct jp = JanCodeHelper.getJanProduct( janCode );


        // TODO fix this to be dynamic
        String warehouseId = [SELECT Id FROM Warehouse__c LIMIT 1].Id;
        InventoryMoveLineWrapper imw = new InventoryMoveLineWrapper( warehouseId, jp );
        //imw.record.JAN_code__c = 'aaa';
        return imw;
    }

    @RemoteAction
    global static Object findBarcode( String barcode ){
        List<Barcode__c> barcodes = [SELECT Id, Name FROM Barcode__c WHERE Name =: barcode LIMIT 1];
        if( barcodes.size() > 0 ){
            return barcodes[0];
        }
        else{
            return null;
        }

    }

    @RemoteAction
    global static Object saveInboundInventoryMove( String objectName, String recordId, String warehouseId, String jsonInput ){


        System.debug( objectName );
        System.debug( recordId );
        System.debug( warehouseId );


        InventoryMoveWrapper imw = InventoryManager.createInventoryMoveWrapper( InventoryMoveWrapper.INBOUND );

        if ( objectName == 'Contact' ) {
            imw.getRecord().donated_from_person__c = recordId;
        }
        if ( objectName == 'Account' ) {
            imw.getRecord().donated_from_company__c = recordId;
        }

        imw.getRecord().transfer_to_warehouse__c = warehouseId;

        List<InventoryMoveLineWrapper> lines = (List<InventoryMoveLineWrapper>) JSON.deserialize(jsonInput, List<InventoryMoveLineWrapper>.class);
        imw.setLines( lines );
        imw.confirmInventoryMove();

        return null;
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
