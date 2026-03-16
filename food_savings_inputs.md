# Food Savings: Data and Parameters Used

This note inventories the inputs used by the food-savings calculation and, importantly, how to answer:
**"What food is saved when MDA is administered?"**

## Direct data inputs
- `country_mda_lo` (formerly `Country_MDA_Lo`)
  - Required columns: `country_title`, `Region`.
- `burden_morb`
  - Required columns: `country_title`, `Parasite`, `AgeClass`, `Infected_aboveT`,
    `Infected_belowT`, `kcals_consumed_year_aboveT`, `kcals_consumed_year_belowT`, `Drug_Efficacy`.
- `cost_cal_df` (formerly `FoodPriceLMIFull2.csv`)
  - Required columns: `country_title`, `food_comp`, `PriceCal`.
  - Optional item column for food-type outputs: one of `Item`, `Commodity`, or `food_item`.

## Core formulas
- Country weighted calorie price:
  - `prop = food_comp * PriceCal`
  - `CostCal = sum(prop) / sum(food_comp)`
- Total annual calories saved due to MDA:
  - `Tot_kcals_consumed_year = ((Infected_aboveT * kcals_consumed_year_aboveT) + (Infected_belowT * kcals_consumed_year_belowT)) * Drug_Efficacy`
- Monetary food savings:
  - `Food_Savings = Tot_kcals_consumed_year * CostCal`
- Sensitivity case:
  - `Cost_Food_Averted_sensitivity = Food_Savings * sensitivity` (default `0.75`)

## Output objects
- `country_totals`: country/region/age/parasite-level calorie and USD savings.
- `region_totals`: region + age aggregates.
- `global_totals`: global + age aggregates.
- `summary_by_region`: final regional and global totals.
- `food_saved_by_item`: **the answer to “what food is saved?”** by country + food item
  - Computed by allocating each country's total saved calories/USD using `food_comp` shares.

## Important interpretation note
- `food_saved_by_item` is an allocation model, not direct observed commodity-specific infection physiology.
- It assumes avoided calorie demand is distributed across the country's diet composition (`food_comp`).

## Upstream dependency context (built earlier in `Parameters2002.R`)
- `Parameters2.xlsx` sheets `Intensity_Infection`, `Parameters2`, and `drug_efficacy`.
- Epidemiology/population pipeline used to derive `TotInfected` and burden strata.
