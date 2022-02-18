
SELECT *
FROM Nashville_Housing_Port.dbo.Nashville_Housing_Table;


-- Standartize Date Format

SELECT SaleDateRaw, CONVERT(date, SaleDateRaw)
FROM Nashville_Housing_Port..Nashville_Housing_Table;

ALTER TABLE Nashville_Housing_Port..Nashville_Housing_Table 
ADD SaleDate Date;

UPDATE Nashville_Housing_Port..Nashville_Housing_Table
SET SaleDate = CONVERT(date, SaleDateRaw);

SELECT SaleDate, SaleDateRaw
FROM Nashville_Housing_Port..Nashville_Housing_Table;


-- Populate NULL Property Addresses

SELECT *
FROM Nashville_Housing_Port..Nashville_Housing_Table
--WHERE PropertyAddress IS NULL
ORDER BY ParcelID;

SELECT complete.ParcelID, complete.PropertyAddress, incomplete.ParcelID, incomplete.PropertyAddress, 
	ISNULL(incomplete.PropertyAddress, complete.PropertyAddress)
FROM Nashville_Housing_Port..Nashville_Housing_Table incomplete
JOIN Nashville_Housing_Port..Nashville_Housing_Table complete
	ON incomplete.ParcelID = complete.ParcelID
	AND incomplete.[UniqueID ] <> complete.[UniqueID ]
WHERE incomplete.PropertyAddress IS NULL;

UPDATE incomplete
SET PropertyAddress = ISNULL(incomplete.PropertyAddress, complete.PropertyAddress)
FROM Nashville_Housing_Port..Nashville_Housing_Table incomplete
JOIN Nashville_Housing_Port..Nashville_Housing_Table complete
	ON incomplete.ParcelID = complete.ParcelID
	AND incomplete.[UniqueID ] <> complete.[UniqueID ]
WHERE incomplete.PropertyAddress IS NULL;

SELECT ParcelID, PropertyAddress
FROM Nashville_Housing_Port..Nashville_Housing_Table
WHERE PropertyAddress IS NULL
ORDER BY PropertyAddress;  -- No output, working correctly


-- Breaking Down Property Addresses (Using substrings)

SELECT PropertyAddress
FROM Nashville_Housing_Port..Nashville_Housing_Table;

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) AS Address,
	SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , Len(PropertyAddress)) AS City
FROM Nashville_Housing_Port..Nashville_Housing_Table

ALTER TABLE Nashville_Housing_Port..Nashville_Housing_Table 
ADD PropertySplitAddress Nvarchar(255), 
	PropertySplitCity Nvarchar(255);

UPDATE Nashville_Housing_Port..Nashville_Housing_Table
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ),
	PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1 , Len(PropertyAddress));

SELECT PropertySplitCity, PropertySplitAddress
FROM Nashville_Housing_Port..Nashville_Housing_Table;


-- Breaking Down Owner Addresses (Using Parsename)

SELECT 
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Nashville_Housing_Port..Nashville_Housing_Table;

ALTER TABLE Nashville_Housing_Port..Nashville_Housing_Table
ADD OwnerSplitAddress Nvarchar(255),
	OwnerSplitCity Nvarchar(255),
	OwnerSplitState Nvarchar(255);

UPDATE Nashville_Housing_Port..Nashville_Housing_Table
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

SELECT OwnerSplitAddress, OwnerSplitCity, OwnerSplitState
FROM Nashville_Housing_Port..Nashville_Housing_Table;


-- Standardize "Sold as Vacant"

SELECT DISTINCT (SoldAsVacant),
	   COUNT(SoldAsVacant)
  FROM Nashville_Housing_Port..Nashville_Housing_Table
 GROUP BY SoldAsVacant
 ORDER BY SoldAsVacant;

SELECT SoldAsVacant,
  CASE SoldAsVacant
	WHEN 'Y' THEN 'Yes'
	WHEN 'N' THEN 'No'
	ELSE SoldAsVacant
  END
FROM Nashville_Housing_Port..Nashville_Housing_Table

UPDATE Nashville_Housing_Port..Nashville_Housing_Table
  SET SoldAsVacant = 
	CASE SoldAsVacant
	  WHEN 'Y' THEN 'Yes'
	  WHEN 'N' THEN 'No'
	  ELSE SoldAsVacant
	END


-- Remove Duplicates

WITH row_num_cte AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM Nashville_Housing_Port..Nashville_Housing_Table
)

SELECT * -- (Then delete)
FROM row_num_cte
WHERE row_num > 1


-- Remove Unused Columns

SELECT *
FROM Nashville_Housing_Port..Nashville_Housing_Table

ALTER TABLE Nashville_Housing_Port..Nashville_Housing_Table
DROP COLUMN SaleDateRaw, OwnerAddress, TaxDistrict, PropertyAddress

