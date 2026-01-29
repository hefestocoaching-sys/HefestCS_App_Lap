// Features barrel file - exports públicos de features/
// NO cambiar imports existentes, este archivo es para uso futuro

// Anthropometry Feature
export 'anthropometry_feature/screen/anthropometry_screen.dart';
export 'anthropometry_feature/screens/anthropometry_record_detail_screen.dart';
export 'anthropometry_feature/screens/anthropometry_records_screen.dart';
export 'anthropometry_feature/widgets/anthropometry_graphs_tab.dart';
export 'anthropometry_feature/widgets/anthropometry_interpretation_tab.dart';
export 'anthropometry_feature/widgets/anthropometry_measures_tab.dart';
export 'anthropometry_feature/widgets/anthropometry_record_header.dart';
export 'anthropometry_feature/widgets/anthropometry_record_tile.dart';
export 'anthropometry_feature/widgets/components/five_c_widgets.dart';

// Auth
export 'auth/presentation/auth_gate.dart';
export 'auth/presentation/login_screen.dart';
export 'auth/presentation/splash_screen.dart';

// Biochemistry Feature
export 'biochemistry_feature/screen/biochemistry_screen.dart';
export 'biochemistry_feature/widgets/biochemistry_comparison_screen.dart';
export 'biochemistry_feature/widgets/biochemistry_tab.dart';

// Calendar Feature
export 'calendar_feature/calendar_screen.dart';

// Client Feature
export 'client_feature/models/client_summary_data.dart';
export 'client_feature/screen/client_overview_screen.dart';

// Client Summary Feature
export 'client_summary_feature/screen/client_summary_screen.dart';

// Common Widgets
export 'common_widgets/record_deletion_dialogs.dart';

// Dashboard Feature
export 'dashboard_feature/dashboard_screen.dart';
export 'dashboard_feature/providers/appointments_provider.dart';
export 'dashboard_feature/providers/pending_tasks_provider.dart';
export 'dashboard_feature/providers/transactions_provider.dart';
export 'dashboard_feature/widgets/alerts_panel_widget.dart';
export 'dashboard_feature/widgets/financial_summary_widget.dart';
export 'dashboard_feature/widgets/pending_tasks_section.dart';
export 'dashboard_feature/widgets/quick_actions_panel.dart';
export 'dashboard_feature/widgets/quick_stat_card.dart';
export 'dashboard_feature/widgets/today_agenda_section.dart';
export 'dashboard_feature/widgets/today_appointments_widget.dart';
export 'dashboard_feature/widgets/today_date_block.dart';
export 'dashboard_feature/widgets/weekly_calendar_widget.dart';
export 'dashboard_feature/workspace_home_screen.dart';

// Finance Feature

// Food Database Feature
export 'food_database_feature/models/food_models.dart';
export 'food_database_feature/screen/food_database_screen.dart';
export 'food_database_feature/widgets/food_item_card.dart';
export 'food_database_feature/widgets/food_search_delegate.dart';
export 'food_database_feature/widgets/food_search_modal.dart';
export 'food_database_feature/widgets/food_search_widget.dart';

// History Clinic Feature
export 'history_clinic_feature/screen/history_clinic_screen.dart';
export 'history_clinic_feature/screens/history_clinic_demo_screen.dart';
export 'history_clinic_feature/tabs/background_tab.dart';
export 'history_clinic_feature/tabs/general_evaluation_tab.dart';
export 'history_clinic_feature/tabs/gyneco_tab.dart';
export 'history_clinic_feature/tabs/personal_data_tab.dart';
export 'history_clinic_feature/tabs/training_evaluation_tab.dart';
export 'history_clinic_feature/viewmodel/history_clinic_view_model.dart';
export 'history_clinic_feature/viewmodel/muscle_volume_buckets.dart';
export 'history_clinic_feature/widgets/client_hero_header.dart';
export 'history_clinic_feature/widgets/clinic_client_header_with_tabs.dart';
export 'history_clinic_feature/widgets/clinic_client_summary_surface.dart';
export 'history_clinic_feature/widgets/clinic_flat_section.dart';
export 'history_clinic_feature/widgets/clinic_section.dart';
export 'history_clinic_feature/widgets/clinic_section_example.dart';
export 'history_clinic_feature/widgets/clinic_summary_frame.dart';
export 'history_clinic_feature/widgets/clinic_summary_shell.dart';
export 'history_clinic_feature/widgets/clinic_tab_item.dart';

// Macros Feature
export 'macros_feature/screen/macros_screen.dart';
export 'macros_feature/screen/macros_week_screen.dart';
export 'macros_feature/viewmodel/macros_view_model.dart';
export 'macros_feature/widgets/macros_content.dart';
export 'macros_feature/widgets/macros_pie_chart_inner.dart';
export 'macros_feature/widgets/macros_pie_chart_outer.dart';
export 'macros_feature/widgets/macros_week_summary_chart.dart';

// Main Shell
export 'main_shell/providers/clients_provider.dart';
export 'main_shell/providers/draft_client_provider.dart';
export 'main_shell/providers/global_date_provider.dart';
export 'main_shell/providers/save_indicator_provider.dart';
export 'main_shell/screen/client_selection_screen.dart';
export 'main_shell/screen/main_shell_screen.dart';
export 'main_shell/widgets/active_date_header.dart';
export 'main_shell/widgets/client_action_panel.dart';
export 'main_shell/widgets/client_list_screen.dart';
export 'main_shell/widgets/client_selector_modal.dart';
export 'main_shell/widgets/client_side_navigation_rail.dart';
export 'main_shell/widgets/client_summary_header.dart';
export 'main_shell/widgets/client_summary_panel.dart';
export 'main_shell/widgets/empty_state_onboarding.dart';
export 'main_shell/widgets/global_date_selector.dart';
export 'main_shell/widgets/global_side_navigation_rail.dart';
export 'main_shell/widgets/inactive_clients_screen.dart';
export 'main_shell/widgets/invitation_code_dialog.dart';
export 'main_shell/widgets/save_indicator_widget.dart';
export 'main_shell/widgets/settings_screen.dart';

// Meal Plan Feature
export 'meal_plan_feature/screen/meal_plan_screen.dart';
export 'meal_plan_feature/widgets/daily_meal_plan_tab.dart';
export 'meal_plan_feature/widgets/meal_card_widget.dart';

// Nutrition Feature
export 'nutrition_feature/models/dietary_state_models.dart';
export 'nutrition_feature/models/nutrition_blocked_state.dart';
export 'nutrition_feature/providers/dietary_provider.dart';
export 'nutrition_feature/providers/nutrition_blocked_provider.dart';
export 'nutrition_feature/providers/nutrition_plan_engine_provider.dart';
export 'nutrition_feature/screen/nutrition_screen.dart';
export 'nutrition_feature/widgets/depletion_tab.dart';
export 'nutrition_feature/widgets/dietary_activity_section.dart';
export 'nutrition_feature/widgets/dietary_adjustment_section.dart';
export 'nutrition_feature/widgets/dietary_tab.dart';
export 'nutrition_feature/widgets/dietary_tmb_section.dart';

// Recipes Feature
export 'recipes_feature/recipes_screen.dart';

// Shared
export 'shared/record_detail/record_detail_shell.dart';
export 'shared/record_detail/record_tab_scaffold.dart';

// Training Feature - Context
export 'training_feature/context/vop_context.dart';

// Training Feature - Domain
export 'training_feature/domain/volume_intelligence/models/intensity_distribution.dart';
export 'training_feature/domain/volume_intelligence/models/psychometric_profile.dart';

// Training Feature - Providers
export 'training_feature/providers/training_plan_provider.dart';

// Training Feature - Screens
export 'training_feature/screens/series_distribution_screen.dart';
export 'training_feature/screens/training_dashboard_screen.dart';
export 'training_feature/screens/training_weeks_overview_screen.dart';
export 'training_feature/training_screen.dart';

// Training Feature - Services
export 'training_feature/services/training_plan_builder.dart';
export 'training_feature/services/training_profile_form_mapper.dart';

// Training Feature - Utils
export 'training_feature/utils/audit_helpers.dart';
export 'training_feature/utils/series_adjustment.dart';

// Training Feature - Widgets
export 'training_feature/widgets/app_icons.dart';
export 'training_feature/widgets/block_label.dart';
export 'training_feature/widgets/exercise_block_widget.dart';
export 'training_feature/widgets/intensity_split_table.dart';
export 'training_feature/widgets/macrocycle_overview_tab.dart';
export 'training_feature/widgets/macrocycle_table.dart';
export 'training_feature/widgets/macrocycle_weekly_calculator_example.dart';
export 'training_feature/widgets/priority_split_table.dart';
export 'training_feature/widgets/series_breakdown_table.dart';
export 'training_feature/widgets/series_calculator_table.dart';
export 'training_feature/widgets/training_analysis_tab.dart';
export 'training_feature/widgets/training_audit_panel.dart';
export 'training_feature/widgets/training_plan_tab.dart';
export 'training_feature/widgets/volume_breakdown_table.dart';
export 'training_feature/widgets/volume_range_muscle_table.dart';
export 'training_feature/widgets/weekly_history_tab.dart';
export 'training_feature/widgets/weekly_plan_tab.dart';
export 'training_feature/widgets/weekly_routine_view.dart';
