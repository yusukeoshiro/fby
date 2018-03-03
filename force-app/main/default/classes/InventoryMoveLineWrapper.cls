public class InventoryMoveLineWrapper {
    public InventoryMoveLine__c record {get;set;}
    public JanProduct janProduct {get;set;}
    public List<Barcode__c> barcodes {get;set;}

    public InventoryMoveLineWrapper( InventoryMoveLine__c iml ) {
        this.record = iml;
        this.barcodes = new List<Barcode__c>();
    }
    public InventoryMoveLineWrapper( JanProduct janProduct ) {
        this.record = new InventoryMoveLine__c();
        this.record.jan_code__c = janProduct.janCode;
        this.record.food_name__c = janProduct.name;
        System.debug( this.record );
        this.janProduct = janProduct;
    }
}
