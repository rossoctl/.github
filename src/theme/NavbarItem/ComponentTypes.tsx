import ComponentTypes from '@theme-original/NavbarItem/ComponentTypes';
import GitHubStars from '@site/src/components/GitHubStars';

// Register the live GitHub star-count navbar item (type: 'custom-gitHubStars').
export default {
  ...ComponentTypes,
  'custom-gitHubStars': GitHubStars,
};
