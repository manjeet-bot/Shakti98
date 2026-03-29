import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/employee_service.dart';
import '../models/employee_model.dart';
import '../screens/employee_form_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final EmployeeService _employeeService = EmployeeService();
  final TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;
  bool _showAdminDialog = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    // Check if admin PIN is already verified in this session
    // For demo purposes, we'll use a simple shared preference approach
    // In production, you might want to use secure storage
  }

  @override
  Widget build(BuildContext context) {
    if (_showAdminDialog && !_isAdmin) {
      return _AdminPINDialog(
        onVerified: (bool verified) {
          setState(() {
            _isAdmin = verified;
            _showAdminDialog = false;
          });
        },
      );
    }

    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Employees'),
          backgroundColor: const Color(0xFF1B5E20),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock,
                size: 64,
                color: Color(0xFF6C757D),
              ),
              SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please enter admin PIN to access employee management',
                style: TextStyle(
                  color: Color(0xFF6C757D),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              _showAdminDialog = true;
            });
          },
          backgroundColor: const Color(0xFF1B5E20),
          child: const Icon(Icons.lock_open),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Management'),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: StreamBuilder<List<Employee>>(
        stream: _employeeService.getAllEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading employees',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final employees = snapshot.data ?? [];

          if (employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Color(0xFF6C757D),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No employees found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first employee to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              return _buildEmployeeTile(employee);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEmployee,
        backgroundColor: const Color(0xFF1B5E20),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmployeeTile(Employee employee) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2E7D32),
          backgroundImage: employee.imageUrl != null && employee.imageUrl!.isNotEmpty
              ? NetworkImage(employee.imageUrl!)
              : null,
          child: employee.imageUrl == null || employee.imageUrl!.isEmpty
              ? Text(
                  employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          employee.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${employee.rank} • ${employee.armyNumber}',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
              ),
            ),
            Text(
              employee.department,
              style: const TextStyle(
                color: Color(0xFF6C757D),
              ),
            ),
            Text(
              'Retirement: ${DateFormat('MMM d, yyyy').format(employee.retirementDate)}',
              style: const TextStyle(
                color: Color(0xFF6C757D),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF6C757D)),
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editEmployee(employee);
                break;
              case 'delete':
                _deleteEmployee(employee);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _editEmployee(employee),
      ),
    );
  }

  void _addEmployee() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmployeeFormScreen(),
      ),
    );
  }

  void _editEmployee(Employee employee) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeFormScreen(employee: employee),
      ),
    );
  }

  void _deleteEmployee(Employee employee) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Employee'),
        content: Text(
          'Are you sure you want to delete ${employee.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _employeeService.deleteEmployee(employee.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Employee deleted successfully'),
                      backgroundColor: Color(0xFF4CAF50),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete employee: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search by Army Number'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            labelText: 'Army Number',
            hintText: 'Enter army number',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final armyNumber = _searchController.text.trim();
              if (armyNumber.isNotEmpty) {
                Navigator.pop(context);
                try {
                  final employees = await _employeeService.searchByArmyNumber(armyNumber);
                  // Show search results
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Search failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Retirement Date'),
        content: const Text('Date filtering functionality would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _AdminPINDialog extends StatefulWidget {
  final Function(bool) onVerified;

  const _AdminPINDialog({required this.onVerified});

  @override
  State<_AdminPINDialog> createState() => _AdminPINDialogState();
}

class _AdminPINDialogState extends State<_AdminPINDialog> {
  final TextEditingController _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isError = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock,
                  size: 64,
                  color: Color(0xFF1B5E20),
                ),
                const SizedBox(height: 16),
                Text(
                  'Admin Access Required',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter admin PIN to access employee management',
                  style: TextStyle(color: Color(0xFF6C757D)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: InputDecoration(
                    labelText: 'Admin PIN',
                    hintText: 'Enter 4-digit PIN',
                    errorText: _isError ? 'Invalid PIN' : null,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (_isError) {
                      setState(() {
                        _isError = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _isLoading ? null : () {
                          widget.onVerified(false);
                        },
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyPIN,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Verify'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _verifyPIN() async {
    final pin = _pinController.text.trim();
    
    if (pin.isEmpty) {
      setState(() {
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate PIN verification
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Default PIN is "1234" for demo purposes
    if (pin == '1234') {
      widget.onVerified(true);
    } else {
      setState(() {
        _isError = true;
      });
    }
  }
}
