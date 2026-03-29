import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:firebase_storage/firebase_storage.dart';

import 'dart:io';

import '../models/employee_model.dart';



class EmployeeService {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseStorage _storage = FirebaseStorage.instance;



  // Get all employees

  Stream<List<Employee>> getAllEmployees() {

    return _firestore

        .collection('employees')

        .orderBy('name')

        .snapshots()

        .map((snapshot) => snapshot.docs

            .map((doc) => Employee.fromFirestore(doc))

            .toList());

  }



  // Search employees by army number

  Future<List<Employee>> searchByArmyNumber(String armyNumber) async {

    final snapshot = await _firestore

        .collection('employees')

        .where('armyNumber', isEqualTo: armyNumber)

        .get();



    return snapshot.docs

        .map((doc) => Employee.fromFirestore(doc))

        .toList();

  }



  // Filter employees by retirement date range

  Future<List<Employee>> filterByRetirementDate(DateTime startDate, DateTime endDate) async {

    final snapshot = await _firestore

        .collection('employees')

        .where('retirementDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))

        .where('retirementDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))

        .get();



    return snapshot.docs

        .map((doc) => Employee.fromFirestore(doc))

        .toList();

  }



  // Get employee by ID

  Future<Employee?> getEmployeeById(String id) async {

    final doc = await _firestore.collection('employees').doc(id).get();

    if (doc.exists) {

      return Employee.fromFirestore(doc);

    }

    return null;

  }



  // Add new employee

  Future<String> addEmployee(Employee employee) async {

    final docRef = _firestore.collection('employees').doc();

    await docRef.set(employee.toFirestore());

    return docRef.id;

  }



  // Update employee

  Future<void> updateEmployee(Employee employee) async {

    await _firestore

        .collection('employees')

        .doc(employee.id)

        .update(employee.toFirestore());

  }



  // Delete employee

  Future<void> deleteEmployee(String id) async {

    await _firestore.collection('employees').doc(id).delete();

  }



  // Upload employee image

  Future<String?> uploadEmployeeImage(dynamic imageFile, String employeeId) async {

    try {

      final ref = _storage

          .ref()

          .child('employee_images')

          .child(employeeId)

          .child('profile.jpg');

      

      // Handle web platform differently

      if (imageFile.toString().contains('http')) {

        // For web, if it's already a URL, return it

        return imageFile.toString();

      }

      

      final uploadTask = await ref.putFile(imageFile);

      return await uploadTask.ref.getDownloadURL();

    } catch (e) {

      print('Error uploading employee image: $e');

      // Return a placeholder URL for demo purposes

      return 'https://via.placeholder.com/150';

    }

  }



  // Delete employee image

  Future<void> deleteEmployeeImage(String employeeId) async {

    try {

      await _storage.ref().child('employee_images/$employeeId').delete();

    } catch (e) {

      // Ignore if image doesn't exist

    }

  }



  // Validate army number uniqueness

  Future<bool> isArmyNumberUnique(String armyNumber, {String? excludeId}) async {

    final snapshot = await _firestore

        .collection('employees')

        .where('armyNumber', isEqualTo: armyNumber)

        .get();



    if (snapshot.docs.isEmpty) {

      return true;

    }



    if (excludeId != null && snapshot.docs.length == 1 && snapshot.docs.first.id == excludeId) {

      return true;

    }



    return false;

  }

}

