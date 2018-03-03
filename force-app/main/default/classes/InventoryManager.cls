/**
    在庫の入出庫や、移動に関するメソッドを提供するHelper Class
*/

public with sharing class InventoryManager {

    public InventoryManager(){

    }

    // create a new instance of InventoryMoveWrapper
    public static InventoryMoveWrapper createInventoryMoveWrapper( Integer moveType ){
        return new InventoryMoveWrapper( new InventoryMove__c(), moveType );        
    }


}
