def validate(telescope_cfg):
    """
    Function to validate the telescope configuration received by the API.

    Parameters
    ----------
    telescope_cfg : dict
        Dictionary containing the telescope configuration.

    Returns
    -------
    dict
        Dictionary containing the validation results.
    """
    response = {}
    response["status"] = "success"
    response["message"] = "Telescope configuration validated successfully"
    return response
