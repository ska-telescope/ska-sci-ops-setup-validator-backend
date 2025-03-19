from ska_sci_ops_setup_validator.validate import validate


def test_validate():
    """
    This is a dummy test put in to make the SKAO CI pipeline happy.
    Replace this once more code is added to the database
    """
    response = validate({})
    assert isinstance(response, dict)
