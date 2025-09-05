# User Management System (BASH Scripts)

A **menu-driven user management system** implemented entirely in **BASH**. This project simulates core user management functionalities including registration, authentication, logout, and reporting. It was developed as a final project for ASE Bucharest.

## Features

- **User Registration**
  - Secure password storage using **SHA-256 hashing**
  - Email confirmation upon account creation
  - Unique ID generation for each user
  - Creation of a personal home directory
  - Validation of user input to prevent duplicates

- **Authentication & Logout**
  - Username and password verification
  - Updates `last_login` field in CSV registry
  - Tracks currently logged-in users
  - Logout functionality to remove users from the session

- **Reporting**
  - Generates **asynchronous reports** for each user
  - Reports include number of files, directories, and disk usage in the home directory
  - Stored in the user’s home folder

- **Text Processing**
  - Uses `sed` for all CSV and text manipulation tasks
  - Modular and maintainable script structure
