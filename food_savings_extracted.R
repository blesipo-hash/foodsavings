# Food savings after MDA
#
# Main entry point: compute_food_savings()
# Returns:
# - country_totals: total calories and USD food savings by country/region/age/parasite
# - region_totals:  total calories and USD food savings by region/age
# - global_totals:  total calories and USD food savings by age (Region = Global)
# - summary_by_region: regional totals with 75% sensitivity case
# - food_saved_by_item: estimated calories and USD savings by country and food item
#
# Goal alignment:
# If your goal is "what food is saved when MDA is administered", use
# `$food_saved_by_item` from the return object.

compute_food_savings <- function(country_mda_lo, burden_morb, cost_cal_df, sensitivity = 0.75) {
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required.")
  }

  required_country <- c("country_title", "Region")
  required_burden <- c(
    "country_title", "Parasite", "AgeClass", "Infected_aboveT", "Infected_belowT",
    "kcals_consumed_year_aboveT", "kcals_consumed_year_belowT", "Drug_Efficacy"
  )
  required_cost <- c("country_title", "food_comp", "PriceCal")

  missing_country <- setdiff(required_country, names(country_mda_lo))
  missing_burden <- setdiff(required_burden, names(burden_morb))
  missing_cost <- setdiff(required_cost, names(cost_cal_df))

  if (length(missing_country) > 0) stop("country_mda_lo missing columns: ", paste(missing_country, collapse = ", "))
  if (length(missing_burden) > 0) stop("burden_morb missing columns: ", paste(missing_burden, collapse = ", "))
  if (length(missing_cost) > 0) stop("cost_cal_df missing columns: ", paste(missing_cost, collapse = ", "))

  # 1) Build country/parasite/age analysis table
  fs_country <- country_mda_lo |>
    dplyr::select(dplyr::all_of(required_country)) |>
    dplyr::left_join(burden_morb, by = "country_title")

  # 2) Country-weighted calorie cost
  cost_cal <- cost_cal_df |>
    dplyr::mutate(prop = food_comp * PriceCal) |>
    dplyr::group_by(country_title) |>
    dplyr::summarise(
      TotalCalProp = sum(prop, na.rm = TRUE),
      TotalFoodcomp = sum(food_comp, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(
      CostCal = dplyr::if_else(TotalFoodcomp > 0, TotalCalProp / TotalFoodcomp, NA_real_)
    )

  # 3) Calories saved and converted to monetary food savings
  fs_country <- fs_country |>
    dplyr::left_join(cost_cal, by = "country_title") |>
    dplyr::mutate(
      Tot_kcals_consumed_year = (
        ((Infected_aboveT * kcals_consumed_year_aboveT) +
           (Infected_belowT * kcals_consumed_year_belowT)) * Drug_Efficacy
      ),
      Food_Savings = Tot_kcals_consumed_year * CostCal
    )

  # 4) Aggregates
  fs_region <- fs_country |>
    dplyr::group_by(Region, AgeClass) |>
    dplyr::summarise(
      Food_Savings = sum(Food_Savings, na.rm = TRUE),
      Tot_kcals_consumed_year = sum(Tot_kcals_consumed_year, na.rm = TRUE),
      .groups = "drop"
    )

  fs_global <- fs_region |>
    dplyr::group_by(AgeClass) |>
    dplyr::summarise(
      Food_Savings = sum(Food_Savings, na.rm = TRUE),
      Tot_kcals_consumed_year = sum(Tot_kcals_consumed_year, na.rm = TRUE),
      .groups = "drop"
    ) |>
    dplyr::mutate(Region = "Global")

  summary_by_region <- rbind(fs_global, fs_region) |>
    dplyr::group_by(Region) |>
    dplyr::summarise(
      Cost_Food_Averted = sum(Food_Savings, na.rm = TRUE),
      Cost_Food_Averted_sensitivity = sum(Food_Savings * sensitivity, na.rm = TRUE),
      .groups = "drop"
    )

  # 5) "What food is saved?" allocation by item.
  # Allocate country total kcal and USD savings using each food item's country food share.
  item_col <- NULL
  for (candidate in c("Item", "Commodity", "food_item")) {
    if (candidate %in% names(cost_cal_df)) {
      item_col <- candidate
      break
    }
  }

  food_saved_by_item <- NULL
  if (!is.null(item_col)) {
    country_total <- fs_country |>
      dplyr::group_by(country_title, Region) |>
      dplyr::summarise(
        total_kcal_saved = sum(Tot_kcals_consumed_year, na.rm = TRUE),
        total_usd_saved = sum(Food_Savings, na.rm = TRUE),
        .groups = "drop"
      )

    food_saved_by_item <- country_total |>
      dplyr::left_join(
        cost_cal_df |>
          dplyr::select(country_title, dplyr::all_of(item_col), food_comp) |>
          dplyr::rename(food_item = dplyr::all_of(item_col)),
        by = "country_title"
      ) |>
      dplyr::mutate(
        kcal_saved_item = total_kcal_saved * food_comp,
        usd_saved_item = total_usd_saved * food_comp
      ) |>
      dplyr::group_by(country_title, Region, food_item) |>
      dplyr::summarise(
        kcal_saved_item = sum(kcal_saved_item, na.rm = TRUE),
        usd_saved_item = sum(usd_saved_item, na.rm = TRUE),
        .groups = "drop"
      )
  }

  list(
    country_totals = fs_country,
    region_totals = fs_region,
    global_totals = fs_global,
    summary_by_region = summary_by_region,
    food_saved_by_item = food_saved_by_item
  )
}

# Convenience wrapper that keeps compatibility with the previously extracted workflow.
# Expects Country_MDA_Lo and burden_morb in the current environment.
run_food_savings_from_repo_inputs <- function(cost_file = "FoodPriceLMIFull2.csv", sensitivity = 0.75) {
  cost_cal_df <- utils::read.csv(cost_file)
  compute_food_savings(
    country_mda_lo = Country_MDA_Lo,
    burden_morb = burden_morb,
    cost_cal_df = cost_cal_df,
    sensitivity = sensitivity
  )
}
