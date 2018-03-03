global with sharing class InboundController {
    global InboundController() {

    }

    @RemoteAction
    global static Object getJanCode( String janCode ){
        JanProduct jp = JanCodeHelper.getJanProduct( janCode );
        InventoryMoveLineWrapper imw = new InventoryMoveLineWrapper( jp );
        //imw.record.JAN_code__c = 'aaa';
        return imw;
    }

    @RemoteAction
    global static Object findBarcode( String barcode ){
        Barcode__c b = [SELECT Id, Name FROM Barcode__c WHERE Name =: barcode LIMIT 1];
        return b;
    }

    @RemoteAction
    global static Object saveInboundInventoryMove( String jsonInput ){

        List<InventoryMoveLineWrapper> lines = (List<InventoryMoveLineWrapper>) JSON.deserialize(jsonInput, List<InventoryMoveLineWrapper>.class);

        //List<InventoryMoveLineWrapper> m = (List<InventoryMoveLineWrapper>) JSON.deserializeUntyped(jsonInput, List<InventoryMoveLineWrapper>);
        //List<InventoryMoveLineWrapper> m = (List<InventoryMoveLineWrapper>) JSON.deserializeUntyped(jsonInput);
        System.debug(lines);


        //List<Object> lines = (List<Object>) m.get('payload');


        Savepoint sp = Database.setSavepoint();
        try{
            InventoryMoveWrapper imw = InventoryManager.createInventoryMoveWrapper( InventoryMoveWrapper.INBOUND );
            UPSERT imw.getRecord();


            List<InventoryMoveLine__c> imls = new List<InventoryMoveLine__c>();
            List<BarcodeAssignment__c> bas = new List<BarcodeAssignment__c>();

            for( InventoryMoveLineWrapper line:lines ){
                line.record.inventory_move__c = imw.getRecord().Id;
                imls.add( line.record );
            }
            UPSERT imls;

            for( InventoryMoveLineWrapper line:lines ){
                System.debug('+++++++');
                System.debug( line.record.Id );
                for( Barcode__c barcode:line.barcodes ){
                    System.debug( barcode );
                    BarcodeAssignment__c ba = new BarcodeAssignment__c();
                    ba.inventory_move_line__c = line.record.Id;
                    ba.barcode__c = barcode.Id;
                    bas.add(ba);
                }
            }

            UPSERT bas;

            //Database.rollback(sp);
        }
        catch( Exception e ){
            System.debug('error!!');
            System.debug(e.getMessage());

            Database.rollback(sp);
        }

        return null;
    }
}
