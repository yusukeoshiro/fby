global with sharing class BarcodePrintController {
    public BarcodePrintController() {

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
