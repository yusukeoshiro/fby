// JANコード取得の為のインスタンス化不要のクラス
// static methodだけ定義される

public with sharing class JanCodeHelper {


    public static JanProduct getJanProduct( String janCode ){
        JanProduct jp = new JanProduct();

        jp.name = 'サッポロ一番 みそラーメン';
        jp.janCode = janCode;
        jp.maker = 'サンヨー食品株式会社';
        jp.netWeight = 100;
        jp.price = 105;
        jp.imageUrl = 'https://item-shopping.c.yimg.jp/i/j/soukai_4901734007159';
        return jp;
    }


}
