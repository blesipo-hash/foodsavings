# Food Savings: Data and Parameters Used

This note inventories the inputs used by the food-savings calculation extracted from `Parameters2002.R`.

## Direct data inputs (used in the extracted block)
- `Country_MDA_Lo`
  - Columns used: `country_title`, `Region`.
- `burden_morb`
  - Columns used: `country_title`, `Parasite`, `AgeClass`, `Infected_aboveT`, `Infected_belowT`,
    `kcals_consumed_year_aboveT`, `kcals_consumed_year_belowT`, `Drug_Efficacy`.
- `FoodPriceLMIFull2.csv`
  - Columns used: `country_title`, `food_comp`, `PriceCal`.

## Upstream data sources required to build direct inputs
- `Parameters2.xlsx` / `Intensity_Infection` sheet
  - Used to create `burden_by_parasite` (`mean_burden` by parasite).
- `Parameters2.xlsx` / `Parameters2` sheet
  - Used to create `params_morb` (`kcal_year_wastedHost`, `Drug_Efficacy` after join).
- `Parameters2.xlsx` / `drug_efficacy` sheet
  - Provides `Drug_Efficacy` by `Parasite`.
- `epi_helminth2` epidemiology data and population joins used earlier in script
  - Used to create `prev_age_country` and `TotInfected`.

## Explicit parameters and assumptions used in the food-savings pathway
- Morbidity-threshold burden ranges by parasite and age class:
  - Ascaris: `a1=0:9`, `a2=0:15`, `a3=0:19`.
  - Trichuris: `t1=0:89`, `t2=0:129`, `t3=0:170`.
  - Hookworm: `h1=0:19`, `h2=0:29`, `h3=0:39`.
  - Schistosoma: `s1=0:170`, `s2=0:170`, `s3=0:170`.
- Dispersion parameters (Chan et al. 1993 values in script):
  - `a_k=0.54`, `t_k=0.23`, `h_k=0.34`, `s_k=0.23`.
- Above-threshold burden constants by parasite/age branch:
  - Ascaris: `10`, `20`, `20`.
  - Trichuris: `90`, `130`, `171`.
  - Hookworm: `20`, `30`, `40`.
  - Schistosoma: `171` (all age classes).
- Calorie-loss conversion parameters used upstream in `params_morb`:
  - `kcal_kg_blood = 1300`.
  - `kcal_kg_tissue = 5000`.

## Core formulas used
- Country weighted calorie price:
  - `prop = food_comp * PriceCal`
  - `CostCal = sum(prop) / sum(food_comp)`
- Total annual calories saved:
  - `Tot_kcals_consumed_year = ((Infected_aboveT * kcals_consumed_year_aboveT) + (Infected_belowT * kcals_consumed_year_belowT)) * Drug_Efficacy`
- Monetary food savings:
  - `Food_Savings = Tot_kcals_consumed_year * CostCal`
- Sensitivity case:
  - `Cost_Food_Averted_75 = Food_Savings * 0.75`
