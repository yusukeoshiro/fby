public class InventoryMoveLineWrapper {
    private InventoryMoveLine__c record {get;set;}
    public JanProduct janProduct {get;set;}
    public List<Barcode__c> barcodes {get;set;}



    public InventoryMoveLine__c getRecord(){
        return this.record;
    }

    public InventoryMoveLineWrapper( InventoryMoveLine__c iml ) {
        this.record = iml;
        this.record.quantity_per_unit__c = 1;
        this.barcodes = new List<Barcode__c>();
    }
    public InventoryMoveLineWrapper( String warehouseId, JanProduct janProduct ) {
        this.record = new InventoryMoveLine__c();
        this.record.quantity_per_unit__c = 1;

        if( janProduct != null ){
            this.record.jan_code__c = janProduct.janCode;
            this.record.food_name__c = janProduct.name;
            this.record.price__c = janProduct.price;

            // see if this jan code already exists
            List<CurrentInventory__c> cis = [
                SELECT Id, jan_code__c, food_type_lOne__c, food_type_lTwo__c,product_name__c
                FROM CurrentInventory__c
                WHERE
                    jan_code__c =: janProduct.janCode AND warehouse__c =: warehouseId
                ORDER BY LasTModifiedDate DESC LIMIT 1
            ];

            if( cis.size() == 0 ){
                cis = [
                    SELECT Id, jan_code__c, food_type_lOne__c, food_type_lTwo__c,product_name__c
                    FROM CurrentInventory__c
                    WHERE
                        jan_code__c =: janProduct.janCode
                    ORDER BY LasTModifiedDate DESC LIMIT 1
                ];
            }

            if( cis.size() > 0 ){
                this.record.food_type_lOne__c = cis[0].food_type_lOne__c;
                this.record.food_type_lTwo__c = cis[0].food_type_lTwo__c;
            }

        }


        this.janProduct = janProduct;
    }
}
