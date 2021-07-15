//
//  PreparingSearchViewController.swift
//  Reciplease
//
//  Created by Guillaume Donzeau on 12/07/2021.
//

import UIKit

class PreparingSearchViewController: ViewController{
    var ingredientsUsed = ""
    var recipesSended = "Bonjour"
    var recipesReceived = [Recette]()
    
    @IBOutlet weak var ingredientName: UITextField!
    @IBOutlet weak var ingredientTableView: UITableView!
    
    
    @IBAction func addIngredientButton(_ sender: UIButton) {
        ingredientName.resignFirstResponder()
        addIngredient()
    }
    @IBAction func searchRecipesButton(_ sender: UIButton) {
        gettingIngredients()
        searchForRecipes(ingredients: ingredientsUsed)
        //performSegue(withIdentifier: "segueToReceiptList", sender: nil)
    }
    @IBAction func dismissKeyboard(_ sender: UITapGestureRecognizer) {
        disMissKeyboardMethod()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ingredientTableView.reloadData()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToReceiptList" {
            let receipListVC = segue.destination as! ReceipeListViewController
            //receipListVC.recipesSended = recipesSended
            receipListVC.recipesReceived = recipesReceived
        }
    }
    func addIngredient() {
        guard var ingredientAdded = ingredientName.text else {
            return
        }
        ingredientAdded = "- " + ingredientAdded
        
        let newIngredient = Ingredient(name: ingredientAdded)
        IngredientService.shared.add(ingredient: newIngredient)
        ingredientName.text = ""
        viewWillAppear(true)
    }
    func gettingIngredients() {
        guard IngredientService.shared.ingredients.count > 0 else {
            let error = APIErrors.nothingIsWritten
            if let errorMessage = error.errorDescription, let errorTitle = error.failureReason {
            allErrors(errorMessage: errorMessage, errorTitle: errorTitle)
            }
            return
        }
        for index in 0 ..< IngredientService.shared.ingredients.count {
            ingredientsUsed += IngredientService.shared.ingredients[index].name
            ingredientsUsed += " "
            print(IngredientService.shared.ingredients[index].name)
        }
        /*
        for element in IngredientService.shared.ingredients {
            ingredientsUsed += element.name
        }
 */
    }
    
    func disMissKeyboardMethod() {
        ingredientName.resignFirstResponder()
    }
    func searchForRecipes(ingredients: String) {
        RecipesServices.shared.getRecipes(ingredients: ingredients) { (result) in
            switch result {
            case .success(let recipes) :
                print("Ok")
                guard recipes.recipes.count > 0 else {
                    let error = APIErrors.nothingIsWritten
                    if let errorMessage = error.errorDescription, let errorTitle = error.failureReason {
                        self.allErrors(errorMessage: errorMessage, errorTitle: errorTitle)
                    }
                    return
                }
                print(recipes.recipes[0].recipe.named)
                self.savingAnswer(recipes:recipes)
                self.performSegue(withIdentifier: "segueToReceiptList", sender: nil)
                
            case .failure(let error) :
                print("KO")
                print(error.errorDescription as Any)
            }
        }
    }
    func savingAnswer(recipes:(Recipes)) { // Converting recipes in an Array before sending it
        recipesReceived = [Recette]() // Let's delete the array between two requests
        for index in 0 ..< recipes.recipes.count {
            // All recipe's characteristics
            let recetteName = recipes.recipes[index].recipe.named
            let image = recipes.recipes[index].recipe.image
            let ingredients = recipes.recipes[index].recipe.ingredientsNeeded
            let timeToPrepare = recipes.recipes[index].recipe.totalTime
            print(image)
            let recette = Recette(name: recetteName, image: image, ingredientsNeeded: ingredients, totalTime: timeToPrepare) // Let's finalizing recipe to add to array
            
            recipesReceived.append(recette)
        }
    }
    private func allErrors(errorMessage: String, errorTitle: String) {
        let alertVC = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        present(alertVC,animated: true,completion: nil)
        //toggleActivityIndicator(shown: false)
    }
}

extension PreparingSearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return IngredientService.shared.ingredients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "IngredientCell", for: indexPath)
        
        let ingredient = IngredientService.shared.ingredients[indexPath.row]
        
        cell.textLabel?.text = ingredient.name
        
        return cell
    }
}
extension PreparingSearchViewController: UITextFieldDelegate { // To dismiss keyboard when returnKey
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        ingredientName.resignFirstResponder()
        ingredientName.text = ""
        return true
    }
}
extension PreparingSearchViewController: UITableViewDelegate { // To delete cells one by one
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            print("On efface : \(indexPath.row)")
            IngredientService.shared.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .bottom)
        }
    }
}
