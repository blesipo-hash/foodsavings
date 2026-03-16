# Extracted from Parameters2002.R: food savings calculation block
#
# Data inputs used directly by this food-savings calculation
# - Country_MDA_Lo (columns used: country_title, Region)
# - burden_morb (columns used: country_title, Parasite, AgeClass,
#   Infected_aboveT, Infected_belowT, kcals_consumed_year_aboveT,
#   kcals_consumed_year_belowT, Drug_Efficacy)
# - FoodPriceLMIFull2.csv (columns used: country_title, food_comp, PriceCal)
#
# Parameters/formulas used directly
# - prop = food_comp * PriceCal
# - CostCal = sum(prop) / sum(food_comp)                    [country-weighted kcal price]
# - Tot_kcals_consumed_year =
#     ((Infected_aboveT * kcals_consumed_year_aboveT) +
#      (Infected_belowT * kcals_consumed_year_belowT)) * Drug_Efficacy
# - Food_Savings = Tot_kcals_consumed_year * CostCal
# - Cost_Food_Averted_75 = Food_Savings * 0.75              [sensitivity case]
#
# Upstream dependency notes (computed earlier in Parameters2002.R)
# - burden_morb is derived from prevalence/burden assumptions and includes
#   morbidity-threshold splits and kcal losses by parasite.

# 1) Build analysis table at country/parasite/age level
fs_country <- Country_MDA_Lo %>%
  dplyr::select(country_title, Region) %>%
  left_join(burden_morb, by = "country_title")

# 2) Compute country-level weighted cost per calorie
Cost_cal <- read.csv("FoodPriceLMIFull2.csv")
Cost_cal$prop <- (Cost_cal$food_comp * Cost_cal$PriceCal)

Cost_cal <- Cost_cal %>%
  group_by(country_title) %>%
  summarise(
    TotalCalProp = sum(prop),
    TotalFoodcomp = sum(food_comp)
  ) %>%
  mutate(CostCal = TotalCalProp / TotalFoodcomp)

# 3) Convert saved calories into dollar-valued food savings
fs_country <- fs_country %>%
  left_join(Cost_cal, by = "country_title") %>%
  mutate(
    Tot_kcals_consumed_year = (
      ((Infected_aboveT * kcals_consumed_year_aboveT) +
         (Infected_belowT * kcals_consumed_year_belowT)) * Drug_Efficacy
    ),
    Food_Savings = (Tot_kcals_consumed_year * CostCal)
  )

# 4) Aggregate outputs
fs_region <- fs_country %>%
  group_by(Region, AgeClass) %>%
  summarise(
    Food_Savings = sum(Food_Savings),
    Tot_kcals_consumed_year = sum(Tot_kcals_consumed_year)
  )

fs_global <- fs_region %>%
  group_by(AgeClass) %>%
  summarise(
    Food_Savings = sum(Food_Savings),
    Tot_kcals_consumed_year = sum(Tot_kcals_consumed_year)
  ) %>%
  mutate(Region = "Global")

Food_Savings <- rbind(fs_global, fs_region) %>%
  group_by(Region) %>%
  summarise(
    Cost_Food_Averted = sum(Food_Savings),
    Cost_Food_Averted_75 = sum(Food_Savings * 0.75)
  )
