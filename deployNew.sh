echo "deleting tmp org..."
sfdx force:org:delete -u tmp -p
echo "creating a new scratch org..."
sfdx force:org:create -f config/project-scratch-def.json -a tmp
echo "pushing code..."
sfdx force:source:push -u tmp

echo "adding permission..."
sfdx force:user:permset:assign -n inventory_management_system_user -u tmp

echo "uploading demo data..."
sfdx force:data:tree:import -p sfdx-out/food_type-FoodTypeLOne__c-FoodTypeLTwo__c-plan.json -u tmp
sfdx force:data:tree:import -f sfdx-out/Warehouse__c.json -u tmp

echo "opening the org..."
sfdx force:org:open -u tmp
