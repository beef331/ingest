import owlkettle

viewable ConfirmationDialog:
  message: string
  confirm: (string, StyleClass) = ("Yes", ButtonSuggested)
  decline: (string, StyleClass) = ("No", ButtonDestructive)

method view*(confirm: ConfirmationDialogState): Widget =
  gui:
    Dialog:
      defaultSize = (500, 200)
      DialogButton {.addButton.}:
        text = confirm.confirm[0]
        style = [confirm.confirm[1]]
        res = DialogAccept

      DialogButton {.addButton.}:
        text = confirm.decline[0]
        style = [confirm.decline[1]]
        res = DialogCancel
      Label:
        text = confirm.message

export ConfirmationDialog
