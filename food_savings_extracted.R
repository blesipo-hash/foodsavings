# Extracted from Parameters2002.R: food savings calculation block
# Inputs expected in environment:
# - Country_MDA_Lo (contains country_title, Region)
# - burden_morb (includes infection counts and kcal burden fields)
# - Drug_Efficacy in burden_morb
# - FoodPriceLMIFull2.csv (country food composition + calories price)

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
