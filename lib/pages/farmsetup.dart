import 'package:farmprecise/Ip.dart';
import 'package:farmprecise/dashboard/dashboard.dart';
import 'package:farmprecise/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FarmSetupForm extends StatefulWidget {
  @override
  _FarmSetupFormState createState() => _FarmSetupFormState();
}

class _FarmSetupFormState extends State<FarmSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _farmerNameController = TextEditingController();
  final TextEditingController _localityController = TextEditingController();
  final TextEditingController _acresController = TextEditingController();
  final TextEditingController _soilTypeController = TextEditingController();
  final TextEditingController _currentCropController = TextEditingController();
  final TextEditingController _pastCropController = TextEditingController();
  String _selectedWaterResource = '';

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      var data = {
        'FARMERNAME': _farmerNameController.text,
        'LOCALITY': _localityController.text,
        'ACRES': _acresController.text,
        'SOILTYPE': _soilTypeController.text,
        'WATERSOURCE': _selectedWaterResource,
        'CURRENTCROP': _currentCropController.text,
        'PASTCROP': _pastCropController.text,
      };

      var url = Uri.parse('http://$ipaddress:3000/farmsetup');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Success'),
              content: Text('Farm setup successful'),
              actions: <Widget>[
                TextButton(
                  child: Text('Okay'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } else {
        // Farm setup failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to setup farm'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Farm Setup Form'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 20),
              TextFormField(
                controller: _farmerNameController,
                decoration: InputDecoration(
                  labelText: 'Farmer’s Name',
                  border: OutlineInputBorder(),
                  hintText: 'Enter farmer’s name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the farmer’s name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _localityController,
                decoration: InputDecoration(
                  labelText: 'Locality',
                  border: OutlineInputBorder(),
                  hintText: 'Enter locality',
                  prefixIcon: Icon(Icons.location_on),
                  suffixIcon: Icon(Icons.search),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the locality';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _acresController,
                decoration: InputDecoration(
                  labelText: 'Acres',
                  border: OutlineInputBorder(),
                  hintText: 'Enter number of acres',
                  prefixIcon: Icon(Icons.landscape),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the number of acres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _soilTypeController,
                decoration: InputDecoration(
                  labelText: 'Soil Type (Optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Enter soil type',
                  prefixIcon: Icon(Icons.grass),
                ),
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Water Resource',
                  border: OutlineInputBorder(),
                ),
                value: _selectedWaterResource.isNotEmpty
                    ? _selectedWaterResource
                    : null,
                items: ['Drip Irrigation', 'Sprinkler', 'Other']
                    .map((label) => DropdownMenuItem(
                          child: Text(label),
                          value: label,
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedWaterResource = value!;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a water resource';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _currentCropController,
                decoration: InputDecoration(
                  labelText: 'Current Crop',
                  border: OutlineInputBorder(),
                  hintText: 'Enter current crop',
                  prefixIcon: Icon(Icons.agriculture),
                ),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter the current crop';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _pastCropController,
                decoration: InputDecoration(
                  labelText: 'Past Crop',
                  border: OutlineInputBorder(),
                  hintText: 'Enter past crop',
                  prefixIcon: Icon(Icons.history),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Color(0xFF06D001), // text color
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
