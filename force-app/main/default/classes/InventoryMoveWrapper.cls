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

            Map<Id, Barcode__c> m = null;

            // create blank map
            for( InventoryMoveLineWrapper line:this.getLines() ){
                String uniqueKey = getUniqueKey(String.valueOf( this.getRecord().transfer_to_warehouse__c ), line);
                uniqueKeys.add( uniqueKey );

                CurrentInventory__c ci = new CurrentInventory__c();
                ci.product_name__c = line.getRecord().food_name__c;
                ci.warehouse__c    = this.getRecord().transfer_to_warehouse__c;
                ci.food_type_lOne__c = line.getRecord().food_type_lOne__c;
                ci.food_type_lTwo__c = line.getRecord().food_type_lTwo__c;
                ci.jan_code__c     = line.getRecord().jan_code__c;
                ci.physical_quantity__c = 0;
                mapCurrentInventory.put( uniqueKey, ci );
            }

            // overwrite the map with whats retrieved from the DB
            List<CurrentInventory__c> lockedCurrentInventoryRecords = [SELECT Id, physical_quantity__c, unique_key__c FROM CurrentInventory__c WHERE unique_key__c IN :uniqueKeys FOR UPDATE]; // LOCK THE RECORDS!!
            for( CurrentInventory__c ci:lockedCurrentInventoryRecords){
                mapCurrentInventory.put( ci.unique_key__c, ci );
            }



        // STEP 3 Update the locked records (inventory) and new InventoryMove records

        // SAVE InventoryMove
        this.getRecord().completion_time__c = Datetime.now();
        UPSERT this.getRecord();


        // SAVE InventoryMoveLines
        List<InventoryMoveLine__c> imls = new List<InventoryMoveLine__c>();
        List<Barcode__c> barcodes = new List<Barcode__c>();

        for( InventoryMoveLineWrapper line:this.getLines() ){
            line.getRecord().inventory_move__c = this.getRecord().Id;
            imls.add( line.getRecord() );
        }
        UPSERT imls;




        // SAVE CurrentInventory
        UPSERT mapCurrentInventory.values();


        // SAVE Barcode
        for( InventoryMoveLineWrapper line:this.getLines() ){

            String uniqueKey = getUniqueKey( String.ValueOf(this.getRecord().transfer_to_warehouse__c), line );
            for( Barcode__c barcode:line.barcodes ){
                barcode.donated_date__c = Date.today();
                // barcode.donated_company__c =  TODO add this
                // barcode.donated_person__c =   TODO add this
                barcode.current_inventory__c = mapCurrentInventory.get( uniqueKey ).Id;
                barcode.shipped_quantity__c = 0;
                barcode.expiration_date__c = line.getRecord().expiration_date__c;
                barcode.original_quantity__c = line.getRecord().quantity_per_unit__c;

                barcodes.add(barcode);
                mapCurrentInventory.get( uniqueKey ).physical_quantity__c += line.getRecord().quantity_per_unit__c; // update inventory quantity
            }
        }
        UPSERT barcodes;




        // SAVE CurrentInventory -- UPDATE Quantity
        UPSERT mapCurrentInventory.values();


        // STEP 4 Commit

        }
        catch( Exception e ){
            Database.rollback(sp);
            System.debug( e.getStackTraceString() );
            throw new AppException( e.getMessage() );
        }


    }

    public void cancelInventoryMove(){

    }

    public void saveInventoryMove(){

    }





    // constructs unique key from InventoryMoveLineWrapper and warehouseId
    private static String getUniqueKey( String warehoudId, InventoryMoveLineWrapper imlw ){
        String uniqueKey =
            String.ValueOf(warehoudId).left(15) + ':' +
            String.ValueOf(imlw.getRecord().food_type_lOne__c).left(15) + ':' +
            String.ValueOf(imlw.getRecord().food_type_lTwo__c).left(15) + ':' +
            imlw.getRecord().jan_code__c;
        return uniqueKey;
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
