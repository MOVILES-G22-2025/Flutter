import 'package:flutter/material.dart';
import 'package:senemarket/common/navigation_bar.dart';
import '../../constants.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  bool _isStarred = false;
  // Agregado: Variable para el índice seleccionado de la navegación
  int _selectedIndex = 0;

  // Agregado: Función para actualizar el índice seleccionado
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí puedes agregar lógica de navegación si lo requieres, por ejemplo:
    // if (index == 0) Navigator.pushNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBarApp(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 50, left: 20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    "Pathways 2B",
                    style: TextStyle(
                      fontFamily: 'Cabin',
                      color: Colors.black,
                      fontSize: 30.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

// CONTENEDOR CON LA IMAGEN
              Container(
                padding: EdgeInsets.only(top: 8, right: 15, bottom: 5),
                //height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                //decoration: BoxDecoration(color: Colors.black),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.network(
                        "https://cdn.sanity.io/images/5vm5yn1d/pro/5cb1f9400891d9da5a4926d7814bd1b89127ecba-1300x867.jpg",
                        width: 350,
                        height: 350,
                        fit: BoxFit
                            .cover, // Ajusta o recorta la imagen para rellenar el contenedor
                      ),
                    )
                  ],
                ),
              ),

//CONTENEDOR CON EL PRECIO Y EL BOTON DE FAVORITOS
              Container(
                padding: EdgeInsets.only(right: 10),
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "\$ 80.000",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isStarred ? Icons.star : Icons.star_border,
                        color: Colors.black,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          _isStarred = !_isStarred;
                        });
                      },
                    ),
                  ],
                ),
              ),

// CONTENEDOR CON CATEGORIA
              Container(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  children: [
                    Text(
                      "Category: ",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "Book",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

// CONTENEDOR CON BOTON DE ANADIR PRODUCTO AL CARRO
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 12, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Add Product"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary30, // Color de fondo
                        foregroundColor:
                            AppColors.secondary0, // Color del texto
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Forma redondeada
                        ),
                      ),
                      child: Text(
                        "Buy Now",
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 22,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        // Acción para "Buy"
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors
                            .primary20, // Puedes usar otro color si lo prefieres
                        foregroundColor: AppColors.secondary0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        "Add to cart",
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

// CONTENEDOR CON LA INFORMACION DEL VENDEDOR
              Container(
                //decoration: BoxDecoration(color: Colors.red),
                padding:
                    EdgeInsets.only(top: 8, bottom: 16, left: 0, right: 16),
                child: Row(
                  // Separar extremos (texto a la izquierda y botón a la derecha)
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Parte izquierda
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Sold by:",
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Mateo Calderón",
                          style: TextStyle(
                            fontFamily: 'Cabin',
                            fontSize: 20,
                          ),
                        ),
                        // Filita para estrellas + número
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.black, size: 20),
                            Icon(Icons.star, color: Colors.black, size: 20),
                            Icon(Icons.star, color: Colors.black, size: 20),
                            Icon(Icons.star, color: Colors.black, size: 20),
                            Icon(Icons.star_half,
                                color: Colors.black, size: 20),
                            SizedBox(width: 4),
                            Text(
                              "(3)",
                              style: TextStyle(
                                fontFamily: 'Cabin',
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Parte derecha: Botón
                    ElevatedButton(
                      onPressed: () {
                        // Acción para abrir chat o lo que desees
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary20, // Color de fondo
                        foregroundColor:
                            AppColors.secondary0, // Color del texto
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Forma redondeada
                        ),
                      ),
                      child: Text(
                        "Talk with the seller",
                        style: TextStyle(
                          fontFamily: 'Cabin',
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

// CONTENEDOR CON LA DESCRIPCION DEL PRODUCTO
              Container(
                padding: EdgeInsets.only(right: 10),
                width: MediaQuery.of(context).size.width,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Description: ",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "English book for the courses English 05 (LENG1155) and English 06 (LENG1156)"
                      "English book for the courses English 05 (LENG1155) and Enlgish 06 (LENG1156"
                      "English book for the courses English 05 (LENG1155) and Enlgish 06 (LENG1156",
                      style: TextStyle(
                        fontFamily: 'Cabin',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
