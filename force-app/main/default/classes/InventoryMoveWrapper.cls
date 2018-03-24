/**
    InventoryMoveは直接操作することはしない。
    必ず、InventoryMoveManager と InventoryMoveWrapperを使って操作をする。
    Transactionを使うので、データの整合性が担保される。
*/

public with sharing class InventoryMoveWrapper {

    private InventoryMove__c record {get;set;}
    private List<InventoryMoveLineWrapper>         lines{get;set;}
    private List<InventoryMoveLineOutboundWrapper> outboundLines{get;set;}
    private Integer moveType {get;set;}


    public static final Integer INBOUND  = 0;
    public static final Integer OUTBOUND = 1;
    public static final Integer TRANSFER = 2;
    public static final Integer DISPOSE  = 3;



    public InventoryMoveWrapper( InventoryMove__c record, Integer moveType ) {
        this.record = record;
        this.record.recordTypeId = getRecordTypeId(moveType);
        this.moveType = moveType;
        this.lines = new List<InventoryMoveLineWrapper>();
        this.outboundLines = new List<InventoryMoveLineOutboundWrapper>();
    }

    public InventoryMove__c getRecord(){
        return this.record;
    }


    private void confirm(){
        this.getRecord().completion_time__c = Datetime.now();
        this.getRecord().move_status__c = 'complete';
        UPSERT this.getRecord();
    }

    public void setLines( List<InventoryMoveLineWrapper> lines ){
        this.lines = lines;
    }

    public List<InventoryMoveLineWrapper> getLines(){
        return this.lines;
    }

    public List<InventoryMoveLine__c> getLineRecords(){
        List<InventoryMoveLine__c> records = new List<InventoryMoveLine__c>();
        for( InventoryMoveLineWrapper w:this.lines ){
            records.add( w.getRecord() );
        }
        return records;
    }

    public List<InventoryMoveLineOutboundWrapper> getOutboundLines(){
        return this.outboundLines;
    }

    public List<InventoryMoveLineOutbound__c> getOutboundLineRecords(){
        List<InventoryMoveLineOutbound__c> records = new List<InventoryMoveLineOutbound__c>();
        for( InventoryMoveLineOutboundWrapper w:this.outboundLines ){
            records.add( w.getRecord() );
        }
        return records;
    }


    private Set<Id> getOutboundBarcodeIds(){
        Set<Id> barcodeIds = new Set<Id>();
        for(InventoryMoveLineOutboundWrapper line:this.outboundLines){
            if( barcodeIds.contains( line.getRecord().barcode__c ) ) throw new AppException('duplicate barcode found'); // duplicate barcode was scanned!
            barcodeIds.add( line.getRecord().barcode__c );
        }
        return barcodeIds;
    }



    public void addInventoryMoveLineOutboundWrapper( InventoryMoveLineOutboundWrapper a ){
        this.outboundLines.add( a );
    }


    /**
        InventoryMoveを保存して必要なトランザクションを実行します。
    */
    public void confirmInventoryMove(){

        if( this.moveType == INBOUND ){

            // STEP 1 Begin transaction
            Savepoint sp = Database.setSavepoint();

            try{

            // STEP 2 Lock the related CurrentInventory, CurrentInventoryLine and related Barcode records

                // get CurrentInventory lines
                Set<String> uniqueKeys = new Set<String>();
                Map<String, CurrentInventory__c> mapCurrentInventory;

                // create uniquekey set
                for( InventoryMoveLineWrapper line:this.getLines() ){
                    uniqueKeys.add( line.getInventoryUniqueKey( this ) );
                }

                // make map from current inventory from DB
                mapCurrentInventory = getUniqueKeyInventoryMap(uniqueKeys); // LOCK RECORDS!

                for( InventoryMoveLineWrapper line:this.getLines() ){
                    if( !mapCurrentInventory.containsKey( line.getInventoryUniquekey( this ) ) ){
                        mapCurrentInventory.put( line.getInventoryUniquekey( this ), new CurrentInventory__c(
                            product_name__c = line.getRecord().food_name__c,
                            warehouse__c = this.getRecord().transfer_to_warehouse__c,
                            food_type_lOne__c = line.getRecord().food_type_lOne__c,
                            food_type_lTwo__c = line.getRecord().food_type_lTwo__c,
                            jan_code__c = line.getRecord().jan_code__c,
                            physical_quantity__c = 0
                        ));
                    }
                }

            // STEP 3 Update the locked records (inventory) and new InventoryMove records

            // SAVE InventoryMove
            this.confirm();


            // SAVE InventoryMoveLines
            List<Barcode__c> barcodes = new List<Barcode__c>();
            List<BarcodeAssignment__c> barcodeAssignments = new List<BarcodeAssignment__c>();

            for( InventoryMoveLineWrapper line:this.getLines() ){ line.getRecord().inventory_move__c = this.getRecord().Id; }
            UPSERT this.getLineRecords();

            // SAVE CurrentInventory
            UPSERT mapCurrentInventory.values();


            // SAVE Barcode
            for( InventoryMoveLineWrapper line:this.getLines() ){

                String uniqueKey = line.getInventoryUniqueKey(this);
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

                    barcodeAssignments.add(new BarcodeAssignment__c( barcode__c = barcode.Id, inventory_move_line_inbound__c = line.getRecord().Id ));
                }
            }
            UPSERT barcodes;

            INSERT barcodeAssignments;


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
        else if(this.moveType == OUTBOUND || this.moveType == DISPOSE){
            // STEP 1 Begin transaction
            Savepoint sp = Database.setSavepoint();

            try{

                // STEP 2 Lock the related CurrentInventory, CurrentInventoryLine and related Barcode records
                    Map<String, CurrentInventory__c> mapInventories;
                    Map<String, Barcode__c>          mapBarcodes;
                    mapBarcodes = new Map<String, Barcode__c>([SELECT Id, current_inventory__c, shipped_quantity__c FROM Barcode__c WHERE Id IN :this.getOutboundBarcodeIds()]);

                    Set<String> inventoryIds = new Set<String>();
                    for(Barcode__c b:mapBarcodes.values()){ inventoryIds.add( b.current_inventory__c );}
                    mapInventories = new Map<String, CurrentInventory__c>([SELECT Id, jan_code__c, warehouse__c, physical_quantity__c FROM CurrentInventory__c WHERE Id IN :inventoryIds FOR UPDATE]);

                // STEP 3 Update the locked records (inventory) and new InventoryMove records
                    this.confirm();

                    for(InventoryMoveLineOutboundWrapper line:this.outboundLines){
                        mapInventories.get(mapBarcodes.get( line.getRecord().barcode__c ).current_inventory__c).physical_quantity__c -= line.getRecord().outbound_quantity__c;
                        mapBarcodes.get( line.getRecord().barcode__c ).shipped_quantity__c += line.getRecord().outbound_quantity__c;
                        line.getRecord().inventory_move__c = this.getRecord().Id;
                    }

                    UPSERT this.getOutboundLineRecords();

                    UPSERT mapBarcodes.values();

                    UPSERT mapInventories.values();

                // STEP 4 Commit

            }
            catch( Exception e ){
                Database.rollback(sp);
                System.debug( e.getStackTraceString() );
                throw new AppException( e.getMessage() );
            }
        }

        else if(this.moveType == TRANSFER){
            // STEP 1 Begin transaction
            Savepoint sp = Database.setSavepoint();

            try{
                // validation
                if( this.record.transfer_from_warehouse__c == null ){
                    throw new AppException( 'transfer_from_warehouse__c is invalid' );
                }
                if( this.record.transfer_to_warehouse__c == null ){
                    throw new AppException( 'transfer_to_warehouse__c is invalid' );
                }








            }
            catch( Exception e ){
                Database.rollback(sp);
                System.debug( e.getStackTraceString() );
                throw new AppException( e.getMessage() );

            }

        }

    }


    private Map<String, CurrentInventory__c> getUniqueKeyInventoryMap( Set<String> uniqueKeys ){
        Map<String, CurrentInventory__c> mapCurrentInventory = new Map<String, CurrentInventory__c>();
        List<CurrentInventory__c> lockedCurrentInventoryRecords = [
            SELECT Id, physical_quantity__c, unique_key__c
            FROM CurrentInventory__c
            WHERE
                unique_key__c IN :uniqueKeys
            FOR UPDATE
        ]; // LOCK THE RECORDS!!


        for( CurrentInventory__c ci:lockedCurrentInventoryRecords){
            mapCurrentInventory.put( ci.unique_key__c, ci );
        }
        return mapCurrentInventory;
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
