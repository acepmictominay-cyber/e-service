-- =====================================================
-- Create payment.transactions table for Xendit Payment
-- Database: MySQL
-- Run this SQL on your MySQL server
-- =====================================================

-- IMPORTANT: The error shows 'payment.transactions' table doesn't exist
-- This could be caused by:
-- 1. The table hasn't been created yet
-- 2. The SQL query uses incorrect quoting (quotes instead of backticks for table with dots)

-- Run this SQL to create the required table:

-- Option 1: Create table with exact name 'payment.transactions' (if using schema/database)
-- NOTE: In MySQL, using dots in table names requires special handling

-- First, check your database name:
-- SHOW DATABASES;
-- USE your_database_name;

-- Option A: Create table with name 'payment_transactions' (recommended - no dots)
CREATE TABLE IF NOT EXISTS `payment_transactions` (
    `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `external_id` VARCHAR(255) NOT NULL UNIQUE COMMENT 'External ID from Xendit/Payment Gateway',
    `transaction_id` VARCHAR(255) COMMENT 'Transaction ID from payment provider',
    `payment_method` VARCHAR(50) COMMENT 'Payment method (EWALLET_OVO, QRIS, VA, etc.)',
    `amount` DECIMAL(15,2) NOT NULL COMMENT 'Payment amount',
    `status` VARCHAR(50) NOT NULL DEFAULT 'PENDING' COMMENT 'Payment status (PENDING, SUCCESS, FAILED, etc.)',
    `metadata` TEXT COMMENT 'JSON metadata from payment provider',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    INDEX `idx_external_id` (`external_id`),
    INDEX `idx_status` (`status`),
    INDEX `idx_created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Option B: If you specifically need 'payment.transactions' (not recommended):
-- CREATE TABLE IF NOT EXISTS `payment`.`transactions` (
--     `id` BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
--     `external_id` VARCHAR(255) NOT NULL UNIQUE,
--     `transaction_id` VARCHAR(255),
--     `payment_method` VARCHAR(50),
--     `amount` DECIMAL(15,2) NOT NULL,
--     `status` VARCHAR(50) NOT NULL DEFAULT 'PENDING',
--     `metadata` TEXT,
--     `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
--     `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP
-- ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
