global with sharing class BarcodeBulkCreateController {
    public BarcodeBulkCreateController() {
    }


    @RemoteAction
    global static String bulkCreateBarcode(Integer quantity){

        System.debug( quantity );
        List<Barcode__c> barcodes = new List<Barcode__c>();
        for(Integer i = 0; i < quantity; i++){
            Barcode__c barcode = new Barcode__c();
            barcodes.add( barcode );
        }

        INSERT barcodes;

        return '成功しました。';

    }
}
