public class InventoryMoveLineOutboundWrapper {
    private InventoryMoveLineOutbound__c record {get;set;}


    public InventoryMoveLineOutbound__c getRecord(){
        return this.record;
    }

    public InventoryMoveLineOutboundWrapper( InventoryMoveLineOutbound__c iml ) {
        this.record = iml;
        this.record.outbound_quantity__c = 1;
    }
}
