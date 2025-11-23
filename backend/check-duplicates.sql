-- Check for duplicate product names
SELECT 
  name, 
  COUNT(*) as count, 
  STRING_AGG(id::text, ', ') as product_ids
FROM "Product"
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY count DESC;
