#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Database Fuzzing Tools Manager
"""

import os
import sys
import subprocess
from pathlib import Path

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
        
        self.tools = {
            "AMOEBA": {"supported_dbs": ["PostgreSQL"]},
            "DQE": {"supported_dbs": ["SQLite", "MySQL"]},
            "SQLancer": {"supported_dbs": ["MySQL", "PostgreSQL", "SQLite"]},
            "SQLRight": {"supported_dbs": ["SQLite", "MySQL", "PostgreSQL"]},
            "Squirrel": {"supported_dbs": ["SQLite", "MySQL", "PostgreSQL", "MariaDB"]},
            "Troc": {"supported_dbs": ["MySQL"]},
            "APOLLO": {"supported_dbs": ["SQLite", "PostgreSQL"]}
        }
        
        self.databases = {
            "MySQL": {"port": 3306},
            "PostgreSQL": {"port": 5432},
            "MariaDB": {"port": 3306},
            "TiDB": {"port": 4000}
        }
        
        self.current_tool = None
        self.current_database = None

    def print_color(self, text, color=Colors.NC):
        print(f"{color}{text}{Colors.NC}")

    def show_header(self):
        os.system('clear' if os.name == 'posix' else 'cls')
        self.print_color("Database Fuzzing Tools Manager", Colors.CYAN)
        self.print_color("=" * 40, Colors.CYAN)
        if self.current_tool:
            self.print_color(f"Tool: {self.current_tool}", Colors.BLUE)
        if self.current_database:
            self.print_color(f"Database: {self.current_database}", Colors.BLUE)
        print()

    def check_docker(self):
        try:
            result = subprocess.run(["docker", "info"], capture_output=True, check=False)
            return result.returncode == 0
        except FileNotFoundError:
            return False

    def show_main_menu(self):
        self.show_header()
        menus = [
            "1) Select Tool",
            "2) Select Database", 
            "3) Start Tool",
            "4) Stop All Tools",
            "5) Check Status",
            "0) Exit"
        ]
        for menu in menus:
            self.print_color(menu, Colors.GREEN)
        print()

    def select_tool(self):
        while True:
            self.show_header()
            self.print_color("Available Tools:", Colors.BLUE)
            for i, tool in enumerate(self.tools.keys(), 1):
                self.print_color(f"{i}) {tool}", Colors.GREEN)
            self.print_color("0) Back", Colors.GREEN)
            
            choice = input("Select tool: ").strip()
            if choice == "0":
                break
            elif choice in [str(i) for i in range(1, len(self.tools)+1)]:
                tool = list(self.tools.keys())[int(choice)-1]
                self.current_tool = tool
                self.print_color(f"Selected: {tool}", Colors.GREEN)
                break

    def select_database(self):
        while True:
            self.show_header()
            self.print_color("Available Databases:", Colors.BLUE)
            for i, db in enumerate(self.databases.keys(), 1):
                self.print_color(f"{i}) {db}", Colors.GREEN)
            self.print_color("0) Back", Colors.GREEN)
            
            choice = input("Select database: ").strip()
            if choice == "0":
                break
            elif choice in [str(i) for i in range(1, len(self.databases)+1)]:
                db = list(self.databases.keys())[int(choice)-1]
                self.current_database = db
                self.print_color(f"Selected: {db}", Colors.GREEN)
                break

    def start_tool(self):
        if not self.current_tool or not self.current_database:
            self.print_color("Please select both tool and database first", Colors.RED)
            return False

        if self.current_database not in self.tools[self.current_tool]["supported_dbs"]:
            self.print_color(f"{self.current_tool} doesn't support {self.current_database}", Colors.RED)
            return False

        self.print_color(f"Starting {self.current_tool} with {self.current_database}...", Colors.BLUE)
        
        # Start database service
        db_dir = self.dbms_dir / self.current_database
        if db_dir.exists():
            os.chdir(db_dir)
            subprocess.run(["docker", "compose", "up", "-d"], check=False)

        # Start tool
        tool_dir = self.tools_dir / self.current_tool
        if tool_dir.exists():
            os.chdir(tool_dir)
            subprocess.run(["docker", "compose", "up", "-d"], check=False)
            self.print_color("Started successfully", Colors.GREEN)
            return True
        return False

    def stop_all_tools(self):
        self.print_color("Stopping all tools...", Colors.BLUE)
        for tool in self.tools.keys():
            tool_dir = self.tools_dir / tool
            if tool_dir.exists():
                os.chdir(tool_dir)
                subprocess.run(["docker", "compose", "down"], check=False)
        
        for db in self.databases.keys():
            db_dir = self.dbms_dir / db
            if db_dir.exists():
                os.chdir(db_dir)
                subprocess.run(["docker", "compose", "down"], check=False)
        
        self.print_color("All tools stopped", Colors.GREEN)

    def check_status(self):
        self.print_color("Checking status...", Colors.BLUE)
        result = subprocess.run(["docker", "ps"], capture_output=True, text=True)
        print(result.stdout)

    def main(self):
        if not self.check_docker():
            self.print_color("Docker not available", Colors.RED)
            sys.exit(1)

        while True:
            try:
                self.show_main_menu()
                choice = input("Select option: ").strip()
                
                if choice == "1":
                    self.select_tool()
                elif choice == "2":
                    self.select_database()
                elif choice == "3":
                    self.start_tool()
                elif choice == "4":
                    self.stop_all_tools()
                elif choice == "5":
                    self.check_status()
                elif choice == "0":
                    self.print_color("Goodbye!", Colors.GREEN)
                    sys.exit(0)
                else:
                    self.print_color("Invalid choice", Colors.RED)
                
                input("Press Enter to continue...")
                    
            except KeyboardInterrupt:
                self.print_color("\nGoodbye!", Colors.GREEN)
                sys.exit(0)

if __name__ == "__main__":
    DatabaseFuzzerManager().main()