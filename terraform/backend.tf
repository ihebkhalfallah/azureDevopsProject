terraform {
  backend "azurerm" {
    # Les paramètres sont passés via -backend-config dans le pipeline
    # pour éviter de stocker des informations sensibles dans le code source
  }
}
