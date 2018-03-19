sfdx force:data:tree:export --query "SELECT Id, Name, (SELECT Name, food_type_lOne__c  FROM food_type_lTwos__r)  FROM FoodTypeLOne__c" \
--outputdir sfdx-out \
--plan --prefix food_type


sfdx force:data:tree:export --query "SELECT Id, Name FROM Warehouse__c" \
--outputdir sfdx-out \
