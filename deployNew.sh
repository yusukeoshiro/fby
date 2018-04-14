echo "deleting test-by8onqc1dosa@example.com org..."
sfdx force:org:delete -u test-by8onqc1dosa@example.com -p
echo "creating a new scratch org..."
sfdx force:org:create -f config/project-scratch-def.json -a test-by8onqc1dosa@example.com
echo "pushing code..."
sfdx force:source:push -u test-by8onqc1dosa@example.com

echo "adding permission..."
sfdx force:user:permset:assign -n inventory_management_system_user

echo "uploading demo data..."
sfdx force:data:tree:import -p sfdx-out/food_type-FoodTypeLOne__c-FoodTypeLTwo__c-plan.json -u test-by8onqc1dosa@example.com
sfdx force:data:tree:import -f sfdx-out/Warehouse__c.json -u test-by8onqc1dosa@example.com

echo "opening the org..."
sfdx force:org:open -u test-by8onqc1dosa@example.com
