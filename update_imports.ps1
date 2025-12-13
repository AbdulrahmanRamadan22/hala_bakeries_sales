# PowerShell script to update all import statements
Write-Host "Updating import statements..." -ForegroundColor Green

$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    $updated = $content
    
    # Update core imports
    $updated = $updated -replace "import 'package:hala_bakeries_sales/core/constants/app_colors.dart'", "import 'package:hala_bakeries_sales/core/theming/app_colors.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/core/theme/app_theme.dart'", "import 'package:hala_bakeries_sales/core/theming/app_theme.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/core/services/connectivity_service.dart'", "import 'package:hala_bakeries_sales/core/helper/connectivity_service.dart'"
    
    # Update Auth imports
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/auth/data/repositories/auth_repository.dart'", "import 'package:hala_bakeries_sales/features/auth/data/repo/auth_repository.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/shared/data/models/user_model.dart'", "import 'package:hala_bakeries_sales/features/auth/data/models/user_model.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/auth/presentation/cubit/login_cubit.dart'", "import 'package:hala_bakeries_sales/features/auth/logic/login_cubit/login_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/auth/presentation/cubit/login_state.dart'", "import 'package:hala_bakeries_sales/features/auth/logic/login_cubit/login_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/auth/presentation/cubit/splash_cubit.dart'", "import 'package:hala_bakeries_sales/features/auth/logic/splash_cubit/splash_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/auth/presentation/cubit/splash_state.dart'", "import 'package:hala_bakeries_sales/features/auth/logic/splash_cubit/splash_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/auth/presentation/pages/login_screen.dart'", "import 'package:hala_bakeries_sales/features/auth/ui/login_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/auth/presentation/pages/splash_screen.dart'", "import 'package:hala_bakeries_sales/features/auth/ui/splash_screen.dart'"
    
    # Update Admin imports - repositories
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/data/repositories/branch_repository.dart'", "import 'package:hala_bakeries_sales/features/admin/data/repo/branch_repository.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/data/repositories/product_repository.dart'", "import 'package:hala_bakeries_sales/features/admin/data/repo/product_repository.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/data/repositories/employee_repository.dart'", "import 'package:hala_bakeries_sales/features/admin/data/repo/employee_repository.dart'"
    
    # Update Admin imports - models
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/shared/data/models/branch_model.dart'", "import 'package:hala_bakeries_sales/features/admin/data/models/branch_model.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/shared/data/models/product_model.dart'", "import 'package:hala_bakeries_sales/features/admin/data/models/product_model.dart'"
    
    # Update Admin imports - cubits
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/admin_dashboard_cubit.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/admin_dashboard_cubit/admin_dashboard_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/admin_dashboard_state.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/admin_dashboard_cubit/admin_dashboard_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/branch_cubit.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/branch_state.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/branch_cubit/branch_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/product_cubit.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/product_state.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/product_cubit/product_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/employee_cubit.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/employee_state.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/employee_cubit/employee_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/report_cubit.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/report_cubit/report_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/cubit/report_state.dart'", "import 'package:hala_bakeries_sales/features/admin/logic/report_cubit/report_state.dart'"
    
    # Update Admin imports - screens
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/admin_dashboard.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/admin_dashboard_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/branch_list_screen.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/branch_list_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/add_branch_screen.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/add_branch_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/product_list_screen.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/product_list_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/add_product_screen.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/add_product_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/employee_list_screen.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/employee_list_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/add_employee_screen.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/add_employee_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/admin/presentation/pages/reports_screen.dart'", "import 'package:hala_bakeries_sales/features/admin/ui/reports_screen.dart'"
    
    # Update Employee imports - repository and models
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/shared/data/repositories/transaction_repository.dart'", "import 'package:hala_bakeries_sales/features/employee/data/repo/transaction_repository.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/shared/data/models/transaction_model.dart'", "import 'package:hala_bakeries_sales/features/employee/data/models/transaction_model.dart'"
    
    # Update Employee imports - cubits
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/cubit/receive_cubit.dart'", "import 'package:hala_bakeries_sales/features/employee/logic/receive_cubit/receive_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/cubit/receive_state.dart'", "import 'package:hala_bakeries_sales/features/employee/logic/receive_cubit/receive_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/cubit/damage_cubit.dart'", "import 'package:hala_bakeries_sales/features/employee/logic/damage_cubit/damage_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/cubit/damage_state.dart'", "import 'package:hala_bakeries_sales/features/employee/logic/damage_cubit/damage_state.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/cubit/stock_cubit.dart'", "import 'package:hala_bakeries_sales/features/employee/logic/stock_cubit/stock_cubit.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/cubit/stock_state.dart'", "import 'package:hala_bakeries_sales/features/employee/logic/stock_cubit/stock_state.dart'"
    
    # Update Employee imports - screens
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/pages/employee_dashboard.dart'", "import 'package:hala_bakeries_sales/features/employee/ui/employee_dashboard_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/pages/receive_goods_screen.dart'", "import 'package:hala_bakeries_sales/features/employee/ui/receive_goods_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/pages/damage_screen.dart'", "import 'package:hala_bakeries_sales/features/employee/ui/damage_screen.dart'"
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/employee/presentation/pages/stock_screen.dart'", "import 'package:hala_bakeries_sales/features/employee/ui/stock_screen.dart'"
    
    # Update Shared imports
    $updated = $updated -replace "import 'package:hala_bakeries_sales/features/shared/presentation/pages/barcode_scanner_screen.dart'", "import 'package:hala_bakeries_sales/features/shared/ui/barcode_scanner_screen.dart'"
    
    if ($content -ne $updated) {
        Set-Content -Path $file.FullName -Value $updated -NoNewline
        Write-Host "Updated: $($file.FullName)" -ForegroundColor Yellow
    }
}

Write-Host "`nImport statements updated successfully!" -ForegroundColor Green
