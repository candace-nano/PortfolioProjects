SELECT * FROM nashville_housing

-- standardize date format

ALTER TABLE nashville_housing
ALTER COLUMN sale_date TYPE DATE

-- populate property address data

SELECT property_address
FROM nashville_housing
WHERE property_address IS NULL

SELECT a.parcel_id, a.property_address, b.parcel_id, b.property_address, COALESCE(a.property_address, b.property_address)
FROM nashville_housing a 
JOIN nashville_housing b
	ON a.parcel_id = b.parcel_id
	AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL
	
UPDATE nashville_housing
SET property_address = COALESCE(a.property_address, b.property_address)
FROM nashville_housing a
JOIN nashville_housing b
	ON a.parcel_id = b.parcel_id
	AND a.unique_id <> b.unique_id
WHERE a.property_address IS NULL

-- breaking out address into individual columns (address, city, state)

SELECT property_address
FROM nashville_housing

SELECT
SUBSTRING(property_address, 1, STRPOS(property_address, ',') -1) AS address,
	SUBSTRING(property_address,  STRPOS(property_address, ',') +1, LENGTH(property_address)) AS city
FROM nashville_housing

ALTER TABLE nashville_housing
ADD property_address_split VARCHAR(250)

UPDATE nashville_housing
SET property_address_split = SUBSTRING(property_address, 1, STRPOS(property_address, ',') -1)

ALTER TABLE nashville_housing
ADD property_city_split VARCHAR(250)

UPDATE nashville_housing
SET property_city_split = SUBSTRING(property_address, STRPOS(property_address, ',') +1, LENGTH(property_address))

SELECT * FROM nashville_housing

-- breaking out owner address into individual columns (address, city, state)

SELECT owner_address
FROM nashville_housing

SELECT
SPLIT_PART(owner_address, ',', 1) AS address,
SPLIT_PART(owner_address, ',', 2) AS city,
SPLIT_PART(owner_address, ',', 3) AS state
FROM nashville_housing

ALTER TABLE nashville_housing
ADD owner_address_split VARCHAR(250)

UPDATE nashville_housing
SET owner_address_split = SPLIT_PART(owner_address, ',', 1)

ALTER TABLE nashville_housing
ADD owner_city_split VARCHAR(250)

UPDATE nashville_housing
SET owner_city_split = SPLIT_PART(owner_address, ',', 2)
									
ALTER TABLE nashville_housing
ADD owner_state_split VARCHAR(250)

UPDATE nashville_housing
SET owner_state_split = SPLIT_PART(owner_address, ',', 3)

-- change Y and N to Yes and No in "sold_as_vacant" field

SELECT DISTINCT(sold_as_vacant), COUNT(sold_as_vacant)
FROM nashville_housing
GROUP BY sold_as_vacant
ORDER BY 2

SELECT sold_as_vacant,
	CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
		WHEN sold_as_vacant = 'N' THEN 'No'
		ELSE sold_as_vacant
		END
FROM nashville_housing

UPDATE nashville_housing
SET sold_as_vacant = CASE WHEN sold_as_vacant = 'Y' THEN 'Yes'
		WHEN sold_as_vacant = 'N' THEN 'No'
		ELSE sold_as_vacant
		END

-- remove duplicates

WITH rom_numCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY parcel_id,
				property_address,
				sale_price,
				sale_date,
				legal_reference
				ORDER BY
					unique_id
					) row_num
	
FROM nashville_housing
)
SELECT *
FROM row_numCTE
WHERE row_num > 1
ORDER BY property_address

WITH rom_numCTE AS(
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY parcel_id,
				property_address,
				sale_price,
				sale_date,
				legal_reference
				ORDER BY
					unique_id
					) row_num
	
FROM nashville_housing
)
DELETE 
FROM row_numCTE
WHERE row_num > 1

-- delete unused columns

SELECT * FROM nashville_housing

ALTER TABLE nashville_housing
DROP COLUMN property_address

ALTER TABLE nashville_housing
DROP COLUMN owner_address

ALTER TABLE nashville_housing
DROP COLUMN tax_district