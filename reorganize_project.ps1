# PowerShell script to reorganize project structure
# Run this from the project root directory

Write-Host "Starting project restructuring..." -ForegroundColor Green

# Create new directory structure
Write-Host "`nCreating new directories..." -ForegroundColor Yellow

# Auth feature directories
New-Item -ItemType Directory -Force -Path "lib/features/auth/data/firebase_services" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/auth/data/models" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/auth/data/repo" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/auth/logic/login_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/auth/logic/splash_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/auth/ui/widgets" | Out-Null

# Admin feature directories
New-Item -ItemType Directory -Force -Path "lib/features/admin/data/firebase_services" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/data/models" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/data/repo" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/logic/admin_dashboard_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/logic/branch_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/logic/product_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/logic/employee_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/logic/report_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/admin/ui/widgets" | Out-Null

# Employee feature directories
New-Item -ItemType Directory -Force -Path "lib/features/employee/data/firebase_services" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/employee/data/models" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/employee/data/repo" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/employee/logic/receive_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/employee/logic/damage_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/employee/logic/stock_cubit" | Out-Null
New-Item -ItemType Directory -Force -Path "lib/features/employee/ui/widgets" | Out-Null

# Shared feature directories
New-Item -ItemType Directory -Force -Path "lib/features/shared/ui" | Out-Null

Write-Host "Directories created successfully!" -ForegroundColor Green

# Move Auth files
Write-Host "`nMoving Auth feature files..." -ForegroundColor Yellow
Move-Item -Path "lib/features/auth/data/repositories/auth_repository.dart" -Destination "lib/features/auth/data/repo/auth_repository.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/shared/data/models/user_model.dart" -Destination "lib/features/auth/data/models/user_model.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/auth/presentation/cubit/login_cubit.dart" -Destination "lib/features/auth/logic/login_cubit/login_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/auth/presentation/cubit/login_state.dart" -Destination "lib/features/auth/logic/login_cubit/login_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/auth/presentation/cubit/splash_cubit.dart" -Destination "lib/features/auth/logic/splash_cubit/splash_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/auth/presentation/cubit/splash_state.dart" -Destination "lib/features/auth/logic/splash_cubit/splash_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/auth/presentation/pages/login_screen.dart" -Destination "lib/features/auth/ui/login_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/auth/presentation/pages/splash_screen.dart" -Destination "lib/features/auth/ui/splash_screen.dart" -Force -ErrorAction SilentlyContinue

# Move Admin files
Write-Host "Moving Admin feature files..." -ForegroundColor Yellow
Move-Item -Path "lib/features/admin/data/repositories/branch_repository.dart" -Destination "lib/features/admin/data/repo/branch_repository.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/data/repositories/product_repository.dart" -Destination "lib/features/admin/data/repo/product_repository.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/data/repositories/employee_repository.dart" -Destination "lib/features/admin/data/repo/employee_repository.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/shared/data/models/branch_model.dart" -Destination "lib/features/admin/data/models/branch_model.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/shared/data/models/product_model.dart" -Destination "lib/features/admin/data/models/product_model.dart" -Force -ErrorAction SilentlyContinue

# Move Admin Cubits
Move-Item -Path "lib/features/admin/presentation/cubit/admin_dashboard_cubit.dart" -Destination "lib/features/admin/logic/admin_dashboard_cubit/admin_dashboard_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/admin_dashboard_state.dart" -Destination "lib/features/admin/logic/admin_dashboard_cubit/admin_dashboard_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/branch_cubit.dart" -Destination "lib/features/admin/logic/branch_cubit/branch_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/branch_state.dart" -Destination "lib/features/admin/logic/branch_cubit/branch_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/product_cubit.dart" -Destination "lib/features/admin/logic/product_cubit/product_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/product_state.dart" -Destination "lib/features/admin/logic/product_cubit/product_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/employee_cubit.dart" -Destination "lib/features/admin/logic/employee_cubit/employee_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/employee_state.dart" -Destination "lib/features/admin/logic/employee_cubit/employee_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/report_cubit.dart" -Destination "lib/features/admin/logic/report_cubit/report_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/cubit/report_state.dart" -Destination "lib/features/admin/logic/report_cubit/report_state.dart" -Force -ErrorAction SilentlyContinue

# Move Admin UI
Move-Item -Path "lib/features/admin/presentation/pages/admin_dashboard.dart" -Destination "lib/features/admin/ui/admin_dashboard_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/pages/branch_list_screen.dart" -Destination "lib/features/admin/ui/branch_list_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/pages/add_branch_screen.dart" -Destination "lib/features/admin/ui/add_branch_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/pages/product_list_screen.dart" -Destination "lib/features/admin/ui/product_list_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/pages/add_product_screen.dart" -Destination "lib/features/admin/ui/add_product_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/pages/employee_list_screen.dart" -Destination "lib/features/admin/ui/employee_list_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/pages/add_employee_screen.dart" -Destination "lib/features/admin/ui/add_employee_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/admin/presentation/pages/reports_screen.dart" -Destination "lib/features/admin/ui/reports_screen.dart" -Force -ErrorAction SilentlyContinue

# Move Employee files
Write-Host "Moving Employee feature files..." -ForegroundColor Yellow
Move-Item -Path "lib/features/shared/data/repositories/transaction_repository.dart" -Destination "lib/features/employee/data/repo/transaction_repository.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/shared/data/models/transaction_model.dart" -Destination "lib/features/employee/data/models/transaction_model.dart" -Force -ErrorAction SilentlyContinue

# Move Employee Cubits
Move-Item -Path "lib/features/employee/presentation/cubit/receive_cubit.dart" -Destination "lib/features/employee/logic/receive_cubit/receive_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/cubit/receive_state.dart" -Destination "lib/features/employee/logic/receive_cubit/receive_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/cubit/damage_cubit.dart" -Destination "lib/features/employee/logic/damage_cubit/damage_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/cubit/damage_state.dart" -Destination "lib/features/employee/logic/damage_cubit/damage_state.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/cubit/stock_cubit.dart" -Destination "lib/features/employee/logic/stock_cubit/stock_cubit.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/cubit/stock_state.dart" -Destination "lib/features/employee/logic/stock_cubit/stock_state.dart" -Force -ErrorAction SilentlyContinue

# Move Employee UI
Move-Item -Path "lib/features/employee/presentation/pages/employee_dashboard.dart" -Destination "lib/features/employee/ui/employee_dashboard_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/pages/receive_goods_screen.dart" -Destination "lib/features/employee/ui/receive_goods_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/pages/damage_screen.dart" -Destination "lib/features/employee/ui/damage_screen.dart" -Force -ErrorAction SilentlyContinue
Move-Item -Path "lib/features/employee/presentation/pages/stock_screen.dart" -Destination "lib/features/employee/ui/stock_screen.dart" -Force -ErrorAction SilentlyContinue

# Move Shared files
Write-Host "Moving Shared feature files..." -ForegroundColor Yellow
Move-Item -Path "lib/features/shared/presentation/pages/barcode_scanner_screen.dart" -Destination "lib/features/shared/ui/barcode_scanner_screen.dart" -Force -ErrorAction SilentlyContinue

Write-Host "`nFile reorganization complete!" -ForegroundColor Green
Write-Host "`nNote: You will need to update all import statements manually or run a find-replace." -ForegroundColor Cyan
Write-Host "The script has moved files but imports still reference old paths." -ForegroundColor Cyan
