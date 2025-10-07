import 'package:farmprecise/pages/homepage.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class RentProductsForm extends StatefulWidget {
  @override
  _RentProductsFormState createState() => _RentProductsFormState();
}

class _RentProductsFormState extends State<RentProductsForm> {
  final _formKey = GlobalKey<FormState>();
  String _selectedProduct =
      'Precision Agricultural Robotic Device-Irrigation'; // Default selection
  DateTime? _selectedDate;
  String _duration = '';
  String _locality = '';
  String _acres = '';

  final List<String> _products = [
    'Precision Agricultural Robotic Device-Irrigation',
    'Precision Agricultural Robotic Device-Weeder',
    'Drone for Precision Agriculture'
  ];

  // List of image URLs for the carousel
  final List<String> _imageUrls = [
    'https://cactilandscape.com/wp-content/uploads/2024/07/Smart-Irrigation-Systems-scaled.jpeg',
    'https://static.producer.com/wp-content/uploads/2019/01/10131530/44-5col-EarthSense-weed-robot.jpg',
    'https://www.bearingtips.com/wp-content/uploads/2021/06/SMB320-Agricultural-drone.jpg',
  ];

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // If all fields are valid, show a success dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Text('Rent Successful'),
              ],
            ),
            content: Text(
                'Your request for $_selectedProduct rental has been submitted.\nWe will reach out to you soon.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rent Products',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image Carousel
              CarouselSlider(
                options: CarouselOptions(
                  height: 200.0,
                  autoPlay: true,
                  autoPlayInterval: Duration(seconds: 2),
                  enlargeCenterPage: true,
                  aspectRatio: 1 / 1,
                  viewportFraction: 0.8,
                ),
                items: _imageUrls.map((url) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        margin: EdgeInsets.symmetric(horizontal: 5.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          image: DecorationImage(
                            image: NetworkImage(url),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
              SizedBox(height: 20.0),

              DropdownButtonFormField<String>(
                value: _selectedProduct,
                isExpanded: true,
                items: _products.map((product) {
                  return DropdownMenuItem<String>(
                    value: product,
                    child: Flexible(
                      child: Text(
                        product,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProduct = value!;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Product',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20.0),

              // Date Picker
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedDate = pickedDate;
                    });
                  }
                },
                readOnly: true,
                controller: TextEditingController(
                  text: _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : '',
                ),
                validator: (value) {
                  if (_selectedDate == null) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),

              // Duration Input
              TextFormField(
                onChanged: (value) {
                  _duration = value;
                },
                decoration: InputDecoration(
                  labelText: 'Duration (in Hours)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the duration';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),

              // Locality Input
              TextFormField(
                onChanged: (value) {
                  _locality = value;
                },
                decoration: InputDecoration(
                  labelText: 'Locality',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the locality';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),

              // Acres Input
              TextFormField(
                onChanged: (value) {
                  _acres = value;
                },
                decoration: InputDecoration(
                  labelText: 'Number of Acres',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the number of acres';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20.0),

              ElevatedButton(
                onPressed: _submitForm,
                child: Text(
                  'Submit',
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
