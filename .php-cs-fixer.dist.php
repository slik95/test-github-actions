<?php

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__)
    ->exclude('var')
    ->exclude('src/Migrations')
    ->exclude('node_modules')
    ->exclude('vendor')
;

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR12' => true,
    ])
    ->setFinder($finder)
    ;
