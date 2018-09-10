global with sharing class BarcodePrintController {
    public String barcodelyUrl {get;set;}

    public BarcodePrintController() {
        BarcodelyUrl__c url = BarcodelyUrl__c.getOrgDefaults();
        if ( url.url__c == null ) {
            this.barcodelyUrl = 'https://barcodely.herokuapp.com/pdf?page_padding=0mm+14mm&barcodes_per_page=44&cell_width=46mm&cell_height=24.8mm&cell_margin=2mm+4mm';
        } else {
            this.barcodelyUrl = url.url__c;
        }
    }




    @RemoteAction
    global static string getCodes( String fromName, String toName ){
        System.debug( fromName );
        System.debug( toName );
        if( fromName == '' || toName == '' ){
            throw new AppException('バーコード番号を入力してください。');
        }

        List<Barcode__c> barcodes = [
            SELECT Name
            FROM Barcode__c
            WHERE
                Name <= :toName AND
                Name >= :fromName
            ORDER BY Name ASC
        ];

        if( barcodes.size() == 0 ){
            throw new AppException('該当するバーコードが存在しませんでした。');
        }

        String returnString = '';

        for( Barcode__c barcode:barcodes ){
            returnString = returnString + barcode.Name + ':';
        }

        return returnString;
    }

}
