<div class="sidebar bg-dark p-4">
    <!-- <h4 class="text-white">Aksharas</h4> -->
    <ul class="list-group">
        <?php
        // Display aksharas as links in the sidebar
        foreach ($aksharas as $akshara) {
            echo '<li class="list-group-item bg-dark"><a href="#' . $akshara . '" class="text-white">' . $akshara . '</a></li>';
        }
        ?>
    </ul>
</div>

<style>
.sidebar {
    position: sticky;
    top: 0;
    height: 100vh;
    overflow-y: auto;
}
.list-group-item {
    border: none;
    padding: 10px 15px;
}
.list-group-item:hover {
    background-color: #343a40;
}
</style>
