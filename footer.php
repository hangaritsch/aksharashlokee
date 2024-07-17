<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shloka Dictionary</title>
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@4.5.2/dist/js/bootstrap.bundle.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/sajari-react-components@4.1.1/dist/index.js"></script>
    <script>
        $(document).ready(function () {
            $('#search').on('keyup', function () {
                var value = $(this).val().toLowerCase();
                $('#shlokas div').filter(function () {
                    $(this).toggle($(this).text().toLowerCase().indexOf(value) > -1);
                });
            });
        });
    </script>
    <script type="module">
        import { Search } from 'https://cdn.jsdelivr.net/npm/sajari-react-components@4.1.1/dist/index.es.js';
        const search = new Search({
            container: '#search-container',
            apiKey: 'b9b93039-1698-488f-855c-9f8585963794',
            collection: 'indian_sanskrit',
            query: '*',
            sort: 'relevance',
            autocomplete: true,
            results: true,
            filters: true,
            facets: true,
            pager: true,
            pageSize: 10
        });
        search.render();
    </script>
    <style>
        .footer {
            position: sticky;
            bottom: 0;
            width: 100%;
            background-color:tan;
            color: white;
            text-align: center;
            padding: 10px 0;
        }
    </style>
</head>
<body class="d-flex flex-column min-vh-100">
    <!-- Your page content goes here -->

    <!-- Footer -->
    <footer class="footer mt-auto">
        <div class="container">
            <span class="text-muted">App developed by Gopalakrishna Hangari</span>
        </div>
    </footer>
</body>
</html>
