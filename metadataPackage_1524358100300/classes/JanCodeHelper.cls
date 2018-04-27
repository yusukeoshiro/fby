// JANコード取得の為のインスタンス化不要のクラス
// static methodだけ定義される

public with sharing class JanCodeHelper {


    public static JanProduct getJanProduct( String janCode ){
        try{
            List<JanProduct> jps = new List<JanProduct>();

            HttpRequest req = new HttpRequest();
            String url = 'https://shopping.yahooapis.jp/ShoppingWebService/V1/json/itemSearch?appid=dj00aiZpPUE0RTNvbjZsSzNmcSZzPWNvbnN1bWVyc2VjcmV0Jng9NGM-&jan=' + janCode;
            req.setEndpoint(url);
            req.setMethod('GET');

            Http http = new Http();
            HTTPResponse res = http.send(req);

            List<Map<String, Object>> productsFound = new List<Map<String, Object>>();

            Map<String,Object> result    = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
            result = (Map<String,Object>) result.get('ResultSet');
            result = (Map<String,Object>) result.get('0');
            result = (Map<String,Object>) result.get('Result');
            for( Integer i = 0; i < 10; i++ ){ // just find the first 10 ignore the rest
                if( result.get(String.valueOf(i)) != null ){
                    productsFound.add(
                        (Map<String,Object>) result.get(String.valueOf(i))
                    );
                }
                else{
                    break;
                }
            }



            for(Map<String, Object> productFound:productsFound){
                JanProduct jp = new JanProduct();
                jp.name = String.valueOf( productFound.get('Name') );
                jp.janCode = janCode;
                jp.maker = null;
                jp.netWeight = null;

                Map<String,Object> price  = (Map<String,Object>) productFound.get('Price');
                jp.price =  Integer.valueOf(price.get('_value'));

                Map<String,Object> image  = (Map<String,Object>) productFound.get('Image');
                jp.imageUrl =  String.valueOf(image.get('Small'));
                jps.add( jp );
            }


            // find the one that has the shortest name:
            Integer max = 10000;
            JanProduct returnValue = null;
            for( JanProduct jp:jps ){
                if( jp.name.length() < max ){
                    max = jp.name.length();
                    returnValue = jp;
                }
            }

            return returnValue;
        }
        catch( Exception e ){
            return null;
        }


/*
        JanProduct jp = new JanProduct();

        jp.name = 'サッポロ一番 みそラーメン';
        jp.janCode = janCode;
        jp.maker = 'サンヨー食品株式会社';
        jp.netWeight = 100;
        jp.price = 105;
        jp.imageUrl = 'https://item-shopping.c.yimg.jp/i/j/soukai_4901734007159';
        return jp;

*/
    }


}
