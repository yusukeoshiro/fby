global with sharing class InboundController {
    global InboundController() {

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
    global static Object saveInboundInventoryMove( String jsonInput ){

        InventoryMoveWrapper imw = InventoryManager.createInventoryMoveWrapper( InventoryMoveWrapper.INBOUND );

        // TODO fix this to be dynamic
        imw.getRecord().transfer_to_warehouse__c = [SELECT Id FROM Warehouse__c LIMIT 1].Id;

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
