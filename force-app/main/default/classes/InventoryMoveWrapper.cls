/**
    InventoryMoveは直接操作することはしない。
    必ず、InventoryMoveManager と InventoryMoveWrapperを使って操作をする。
    Transactionを使うので、データの整合性が担保される。
*/

public with sharing class InventoryMoveWrapper {

    private InventoryMove__c record {get;set;}
    private List<InventoryMoveLineWrapper> lines{get;set;}



    public static final Integer INBOUND  = 0;
    public static final Integer OUTBOUND = 1;
    public static final Integer TRANSFER = 2;
    public static final Integer DISPOSE  = 3;



    public InventoryMoveWrapper( InventoryMove__c record, Integer moveType ) {
        this.record = record;
        this.record.recordTypeId = getRecordTypeId(moveType);
    }

    public InventoryMove__c getRecord(){
        return this.record;
    }

    public void setLines( List<InventoryMoveLineWrapper> lines ){
        this.lines = lines;
    }

    public List<InventoryMoveLineWrapper> getLines(){
        return this.lines;
    }



    /**
        InventoryMoveを保存して必要なトランザクションを実行します。
    */
    public void confirmInventoryMove(){

        // STEP 1 Begin transaction
        Savepoint sp = Database.setSavepoint();

        try{

        // STEP 2 Lock the related CurrentInventory, CurrentInventoryLine and related Barcode records
            // get CurrentInventory lines
            Set<String> uniqueKeys = new Set<String>();
            Map<String, CurrentInventory__c> mapCurrentInventory = new Map<String, CurrentInventory__c>();

            for( InventoryMoveLineWrapper line:this.getLines() ){

                String uniqueKey =
                    String.ValueOf(this.getRecord().transfer_to_warehouse__c).left(15) + ':' +
                    String.ValueOf(line.getRecord().food_type_l1__c)         .left(15) + ':' +
                    String.ValueOf(line.getRecord().food_type_l2__c)         .left(15) + ':' +
                    line.getRecord().jan_code__c;
                uniqueKeys.add(uniqueKey);
            }
            System.debug( uniqueKeys );


            for( CurrentInventory__c ci:[SELECT Id, physical_quantity__c, unique_key__c FROM CurrentInventory__c WHERE unique_key__c IN :uniqueKeys ] ){
                mapCurrentInventory.put( ci.unique_key__c, ci );
            }
            for( String uniqueKey:uniqueKeys ){
                if( !mapCurrentInventory.containsKey( uniqueKey ) ){
                    CurrentInventory__c ci = new CurrentInventory__c();
                    List<String> ids = uniqueKey.split(':');
                    // ci.product_name__c = TODO put in the product name
                    ci.warehouse__c    = ids[0];
                    ci.food_type_l1__c = ids[1];
                    ci.food_type_l2__c = ids[2];
                    ci.jan_code__c     = ids[3];
                    ci.physical_quantity__c = 0;
                    mapCurrentInventory.put( uniqueKey, ci );
                }
            }




        // STEP 3 Update the locked records
        this.getRecord().completion_time__c = Datetime.now();
        UPSERT this.getRecord();

        List<InventoryMoveLine__c> imls = new List<InventoryMoveLine__c>();
        List<BarcodeAssignment__c> bas = new List<BarcodeAssignment__c>();

        for( InventoryMoveLineWrapper line:this.getLines() ){
            line.getRecord().inventory_move__c = this.getRecord().Id;
            imls.add( line.getRecord() );
        }
        UPSERT imls;

        for( InventoryMoveLineWrapper line:this.getLines() ){

            String uniqueKey =
                String.ValueOf(this.getRecord().transfer_to_warehouse__c).left(15) + ':' +
                String.ValueOf(line.getRecord().food_type_l1__c)         .left(15) + ':' +
                String.ValueOf(line.getRecord().food_type_l2__c)         .left(15) + ':' +
                line.getRecord().jan_code__c;

            for( Barcode__c barcode:line.barcodes ){
                BarcodeAssignment__c ba = new BarcodeAssignment__c();
                ba.inventory_move_line__c = line.getRecord().Id;
                ba.barcode__c = barcode.Id;
                bas.add(ba);

                mapCurrentInventory.get( uniqueKey ).physical_quantity__c += line.getRecord().quantity_per_unit__c;

            }
        }
        UPSERT bas;

        UPSERT mapCurrentInventory.values();

        // STEP 4 Commit

        }
        catch( Exception e ){
            Database.rollback(sp);
            throw new AppException( e.getMessage() );
        }



    }

    public void cancelInventoryMove(){

    }

    public void saveInventoryMove(){

    }



    private static String getRecordTypeId( Integer moveType ){
        String tmpRecordTypeId = null;
        if( moveType == InventoryMoveWrapper.INBOUND ){
            tmpRecordTypeId = Schema.SObjectType.InventoryMove__c.getRecordTypeInfosByName().get('入庫').getRecordTypeId();
        }
        else if( moveType == InventoryMoveWrapper.OUTBOUND ){
            tmpRecordTypeId = Schema.SObjectType.InventoryMove__c.getRecordTypeInfosByName().get('出庫').getRecordTypeId();
        }
        else if( moveType == InventoryMoveWrapper.TRANSFER ){
            tmpRecordTypeId = Schema.SObjectType.InventoryMove__c.getRecordTypeInfosByName().get('倉庫間移動').getRecordTypeId();
        }
        else if( moveType == InventoryMoveWrapper.DISPOSE ){
            tmpRecordTypeId = Schema.SObjectType.InventoryMove__c.getRecordTypeInfosByName().get('廃棄').getRecordTypeId();
        }
        if( String.isEmpty(tmpRecordTypeId) ) throw new AppException('invalid record type');

        return tmpRecordTypeId;
    }
}
