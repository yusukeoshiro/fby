echo "deleting test-4tpomppemb6y@example.com org..."
sfdx force:org:delete -u test-4tpomppemb6y@example.com -p
echo "creating a new scratch org..."
sfdx force:org:create -f config/project-scratch-def.json -a test-4tpomppemb6y@example.com
echo "pushing code..."
sfdx force:source:push -u test-4tpomppemb6y@example.com

echo "adding permission..."
sfdx force:user:permset:assign -n inventory_management_system_user -u test-4tpomppemb6y@example.com

echo "uploading demo data..."
sfdx force:data:tree:import -p sfdx-out/food_type-FoodTypeLOne__c-FoodTypeLTwo__c-plan.json -u test-4tpomppemb6y@example.com
sfdx force:data:tree:import -f sfdx-out/Warehouse__c.json -u test-4tpomppemb6y@example.com

echo "opening the org..."
sfdx force:org:open -u test-4tpomppemb6y@example.com
