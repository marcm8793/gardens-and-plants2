class PlantTagsController < ApplicationController
  before_action :set_plant, only: %i[new create]

  def new
    @plant_tag = PlantTag.new
  end

  def create
    tag_ids = plant_tags_params[:tag_id] # ["", "1", "3", "4"]
    # On récupère tous les tags que l'utilisateur a selectionné dans le formulaire,
    # `.where`` peut prendre des tableaux de données pour retourner toutes les occurrences correspondantes
    tags = Tag.where(id: tag_ids)
    # On initialise une variable pour savoir si la transaction a été effectuée avec succès
    # il est nécessaire de l'instancier en dehors du bloc transaction pour pouvoir l'utiliser en dehors de celui-ci (question de scope)
    transaction_committed = false
    # On encapsule toutes les modifications que l'on veut effectuer à l'intérieur d'un bloc transaction
    # Si une erreur survient, on peut rollback (annuler) toutes les modifications effectuées en levant une exception ActiveRecord::Rollback
    ActiveRecord::Base.transaction do
      # On crée une instance de PlantTag pour chaque tag sélectionné
      # On vérifie que toutes les instances ont été sauvegardées en vérifiant que la méthode save retourne true pour toutes les instances
      transaction_committed = tags.any? && tags.all? { |tag| PlantTag.new(tag: tag, plant: @plant).save }
      # Si une des instances n'a pas été sauvegardée, on lève une exception ActiveRecord::Rollback
      # Cela annulera toutes les modifications effectuées dans le bloc transaction, aucun PlantTag ne sera créé
      raise ActiveRecord::Rollback unless transaction_committed
    end

    if transaction_committed
      # Si transaction_committed est true, on redirige l'utilisateur vers la page du jardin du plant
      redirect_to garden_path(@plant.garden)
    else
      # Si transaction_committed est false, on redirige l'utilisateur vers le formulaire de création de plant_tag
      # Il vous sera possible plus tard d'afficher des "flashes" pour informer l'utilisateur de l'erreur
      # de cette façon: flash[:alert] = "An error occured"
      # Il faut aussi réinstancier @plant_tag pour que le formulaire soit pré-rempli avec les données précédemment soumises
      @plant_tag = PlantTag.new
      # On ajoute un message d'erreur au modèle pour afficher un message d'erreur dans la vue
      error_message = tags.any? ? ": An error occured" : ": Please select at least one tag"
      @plant_tag.errors.add(:tag_id, error_message)
      # On redirige l'utilisateur vers le formulaire de création de plant_tag
      render :new, status: :unprocessable_entity
    end
  end

  private

  def plant_tags_params
    # L'input autorise la selection multiple, il faut donc autoriser les arrays de données en provenance du form dans les params
    params.require(:plant_tag).permit(tag_id: [])
  end

  def set_plant
    @plant = Plant.find(params[:plant_id])
  end
end
