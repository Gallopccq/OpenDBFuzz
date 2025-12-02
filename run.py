#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Database Fuzzing Tools Manager
"""

import os
import sys
import subprocess
from pathlib import Path
from typing import Dict, List

class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

class DatabaseFuzzerManager:
    def __init__(self):
        self.script_dir = Path(__file__).parent.absolute()
        self.tools_dir = self.script_dir / "Fuzzers"
        self.dbms_dir = self.script_dir / "DBMSs"
        self.config_dir = self.script_dir / "config"
        
        # Tools and databases configuration
        self.tools = {
            "AMOEBA": {"desc": "Fuzzing tool", "supported_dbs": ["PostgreSQL"]},
            "DQE": {"desc": "Fuzzing tool", "supported_dbs": ["SQLite", "MySQL"]},
            "SQLancer": {"desc": "Logical bug fuzzing tool", "supported_dbs": ["MySQL", "PostgreSQL", "SQLite", "MariaDB","TiDB"]},
            "SQLRight": {"desc": "Coverage-guided fuzzing tool", "supported_dbs": ["SQLite", "MySQL", "PostgreSQL"]},
            "Squirrel": {"desc": "Fuzzing tool based on AFL++", "supported_dbs": ["SQLite", "MySQL", "PostgreSQL", "MariaDB"]},
            "Troc": {"desc": "Transaction testing", "supported_dbs": ["MySQL","MariaDB"]},
            "APOLLO": {"desc": "Fuzzing tool", "supported_dbs": ["SQLite", "PostgreSQL","CockroachDB"]},
            "Radar": {"desc": "Fuzzing tool", "supported_dbs":["SQLite"]}
        }
        
        self.databases = {
            "MySQL": {"desc": "MySQL Database Server", "port": 3306},
            "PostgreSQL": {"desc": "PostgreSQL Database Server", "port": 5432},
            "MariaDB": {"desc": "MariaDB Database Server", "port": 3306},
            "TiDB": {"desc": "TiDB Distributed Database", "port": 4000}
        }
        
        self.current_tool = None
        self.current_database = None

    def print_color(self, text: str, color: str = Colors.NC) -> None:
        print(f"{color}{text}{Colors.NC}")

    def print_error(self, text: str) -> None:
        self.print_color(f"Error: {text}", Colors.RED)

    def print_success(self, text: str) -> None:
        self.print_color(f"✓ {text}", Colors.GREEN)

    def print_info(self, text: str) -> None:
        self.print_color(text, Colors.BLUE)

    def show_header(self) -> None:
        os.system('clear' if os.name == 'posix' else 'cls')
        self.print_color("=" * 60, Colors.CYAN)
        self.print_color("Database Fuzzing Tools Manager".center(60), Colors.CYAN)
        self.print_color("=" * 60, Colors.CYAN)
        
        if self.current_tool:
            self.print_color(f"Current Tool: {self.current_tool}", Colors.BLUE)
        else:
            self.print_color(f"Current Tool: ", Colors.BLUE)
        if self.current_database:
            self.print_color(f"Current Database: {self.current_database}", Colors.BLUE)
        else:
            self.print_color(f"Current Database: ", Colors.BLUE)
        print()

    def check_docker(self) -> bool:
        try:
            result = subprocess.run(["docker", "info"], capture_output=True, check=False)
            return result.returncode == 0
        except FileNotFoundError:
            self.print_error("Docker is not installed")
            return False

    def check_network(self) -> bool:
        try:
            result = subprocess.run(["docker", "network", "inspect", "mynet"], capture_output=True, check=False)
            if result.returncode != 0:
                self.print_info("Creating Docker network: mynet")
                subprocess.run(["docker", "network", "create", "mynet"], check=True)
            return True
        except Exception as e:
            self.print_error(f"Network creation failed: {e}")
            return False

    def show_main_menu(self) -> None:
        self.show_header()
        menus = [
            "1) Select Fuzzing Tool",
            "2) Select Database", 
            "3) Start Tool with Database",
            "4) Stop All Tools",
            "5) Check Tool Status",
            "6) Database Management",
            "0) Exit"
        ]
        for menu in menus:
            self.print_color(menu, Colors.GREEN)
        print()

    def show_tool_menu(self) -> None:
        self.show_header()
        self.print_color("Available Fuzzing Tools:", Colors.BLUE)
        for i, tool in enumerate(self.tools.keys(), 1):
            desc = self.tools[tool]["desc"]
            supported = ", ".join(self.tools[tool]["supported_dbs"])
            self.print_color(f"  {i}) {tool} - {desc}", Colors.GREEN)
            self.print_color(f"     Supported: {supported}", Colors.YELLOW)
            print()
        self.print_color("  0) Back", Colors.GREEN)

    def show_database_menu(self) -> None:
        self.show_header()
        self.print_color("Available Databases:", Colors.BLUE)
        for i, db in enumerate(self.databases.keys(), 1):
            desc = self.databases[db]["desc"]
            port = self.databases[db]["port"]
            self.print_color(f"  {i}) {db} - {desc} (Port: {port})", Colors.GREEN)
            
            supported_tools = [t for t, info in self.tools.items() if db in info["supported_dbs"]]
            if supported_tools:
                self.print_color(f"     Tools: {', '.join(supported_tools)}", Colors.YELLOW)
            print()
        self.print_color("  0) Back", Colors.GREEN)

    def select_tool(self) -> None:
        while True:
            self.show_tool_menu()
            choice = input("Select tool [0-8]: ").strip()
            
            if choice == "0":
                break
            elif choice in [str(i) for i in range(1, 9)]:
                tool = list(self.tools.keys())[int(choice)-1]
                self.current_tool = tool
                self.print_success(f"Selected: {tool}")
                
                # Auto-select first supported database
                supported_dbs = self.tools[tool]["supported_dbs"]
                if not self.current_database and supported_dbs:
                    self.current_database = supported_dbs[0]
                    self.print_success(f"Auto-selected: {self.current_database}")
                break
            else:
                self.print_error("Invalid selection")

    def select_database(self) -> None:
        while True:
            self.show_database_menu()
            choice = input("Select database [0-4]: ").strip()
            
            if choice == "0":
                break
            elif choice in [str(i) for i in range(1, 5)]:
                db = list(self.databases.keys())[int(choice)-1]
                
                # Check compatibility
                if self.current_tool and db not in self.tools[self.current_tool]["supported_dbs"]:
                    self.print_error(f"{self.current_tool} doesn't support {db}")
                    continue
                    
                self.current_database = db
                self.print_success(f"Selected: {db}")
                break
            else:
                self.print_error("Invalid selection")

    def start_database_service(self, database: str) -> bool:
        if database.lower() == "sqlite":
            return True
        db_dir = self.dbms_dir / database
        if not db_dir.exists():
            self.print_error(f"Database directory not found: {db_dir}")
            return False
        
        try:
            os.chdir(db_dir)
            result = subprocess.run(["docker", "compose", "up", "-d"], check=False)
            if result.returncode == 0:
                self.print_success(f"{database} service started")
                return True
            return False
        except Exception as e:
            self.print_error(f"Failed to start {database}: {e}")
            return False

    def start_tool_with_database(self) -> bool:
        if not self.current_tool or not self.current_database:
            self.print_error("Please select both tool and database first")
            return False

        tool, database = self.current_tool, self.current_database
        
        # Check compatibility
        if database not in self.tools[tool]["supported_dbs"]:
            self.print_error(f"{tool} doesn't support {database}")
            return False

        self.print_info(f"Starting {tool} with {database}...")
        
        # Start database first
        if not self.start_database_service(database):
            return False

        # Start tool
        tool_dir = self.tools_dir / tool
        if not tool_dir.exists():
            self.print_error(f"Tool directory not found: {tool_dir}")
            return False

        try:
            os.chdir(tool_dir)
            
            # Try different startup methods
            run_script = tool_dir / f"run-{tool.lower()}.sh"
            if run_script.exists():
                run_script.chmod(0o755)
                env = os.environ.copy()
                env['TARGET_DB'] = database
                result = subprocess.run([f"./run-{tool.lower()}.sh"], env=env, check=False)
            else:
                # Use docker-compose
                result = subprocess.run(["docker", "compose", "up", "-d"], check=False)
            
            # Check if started successfully
            if result.returncode == 0:
                self.print_success(f"{tool} with {database} started")
                return True
            return False
                
        except Exception as e:
            self.print_error(f"Failed to start {tool}: {e}")
            return False

    def stop_all_tools(self) -> None:
        self.print_info("Stopping all tools and databases...")
        
        # Stop tools
        for tool in self.tools.keys():
            tool_dir = self.tools_dir / tool
            if tool_dir.exists():
                os.chdir(tool_dir)
                subprocess.run(["docker", "compose", "down"], check=False)
        
        # Stop databases
        for db in self.databases.keys():
            db_dir = self.dbms_dir / db
            if db_dir.exists():
                os.chdir(db_dir)
                subprocess.run(["docker", "compose", "down"], check=False)
        
        self.print_success("All services stopped")

    def check_status(self) -> None:
        self.print_info("Current Docker container status:")
        result = subprocess.run(["docker", "ps", "--format", "table {{.Names}}\\t{{.Status}}"], 
                               capture_output=True, text=True, check=False)
        print(result.stdout if result.stdout else "No containers running")

    def database_management(self) -> None:
        if not self.current_database:
            self.print_error("No database selected")
            return

        while True:
            self.show_header()
            self.print_color(f"Database Management - {self.current_database}", Colors.BLUE)
            menus = [
                "1) Start Database",
                "2) Stop Database", 
                "3) Check Status",
                "0) Back"
            ]
            for menu in menus:
                self.print_color(menu, Colors.GREEN)
            
            choice = input("Select operation: ").strip()
            
            if choice == "0":
                break
            elif choice == "1":
                self.start_database_service(self.current_database)
            elif choice == "2":
                db_dir = self.dbms_dir / self.current_database
                if db_dir.exists():
                    os.chdir(db_dir)
                    subprocess.run(["docker", "compose", "down"], check=False)
                    self.print_success(f"{self.current_database} stopped")
            elif choice == "3":
                self.check_status()
            else:
                self.print_error("Invalid selection")
            
            input("Press Enter to continue...")

    def init_environment(self) -> None:
        """Initialize environment"""
        self.tools_dir.mkdir(exist_ok=True)
        self.dbms_dir.mkdir(exist_ok=True)
        
        if not self.check_docker():
            sys.exit(1)
        self.check_network()

    def main(self) -> None:
        self.init_environment()
        
        while True:
            try:
                self.show_main_menu()
                choice = input("Select option [0-6]: ").strip()
                
                if choice == "1":
                    self.select_tool()
                elif choice == "2":
                    self.select_database()
                elif choice == "3":
                    if not self.current_tool or not self.current_database:
                        self.print_error("Please select tool and database first")
                    else:
                        self.start_tool_with_database()
                elif choice == "4":
                    self.stop_all_tools()
                elif choice == "5":
                    self.check_status()
                elif choice == "6":
                    self.database_management()
                elif choice == "0":
                    self.print_success("Goodbye!")
                    sys.exit(0)
                else:
                    self.print_error("Invalid selection")
                
                input("Press Enter to continue...")
                    
            except KeyboardInterrupt:
                self.print_success("\nGoodbye!")
                sys.exit(0)
            except Exception as e:
                self.print_error(f"Error: {e}")

if __name__ == "__main__":
    DatabaseFuzzerManager().main()