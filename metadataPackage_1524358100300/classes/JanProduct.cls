// API経由で取得した製品情報を格納するためのオブジェクト

public with sharing class JanProduct {
    public String name {get;set;}
    public String janCode {get;set;}
    public String maker {get;set;}
    public Integer netWeight {get;set;} // in grams
    public Integer price {get;set;}
    public String imageUrl {get;set;}


    public JanProduct() {

    }
}
